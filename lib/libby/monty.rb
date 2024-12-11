require "fileutils"
require "tempfile"
require_relative "../arg_checker/arg_checker"
require_relative "../box_box/box_box"
require_relative "../box_box/enums"
require_relative "../file_herder/file_herder"
require_relative "./libby"
require_relative "../strink/strink"

module SaladPrep
	using Strink

	class Monty < Libby

		attr_reader :min_version

		def initialize(
			egg,
			min_version:"3.9",
			generated_file_dir: nil,
			log: nil
		)
			super(log: log)
			@egg = egg
			@min_version = min_version
			raise "generated_file_dir is required" if generated_file_dir.zero?
			@generated_file_dir = generated_file_dir
		end

		def py_env_path
			File.join(
				@egg.app_root,
				@egg.app_trunk,
				@egg.file_prefix
			)
		end

		def py_env_activate_path
			File.join(
					py_env_path,
					"bin",
					"activate"
				)
		end

		def sync_requirement_list
			requirements_src = File.join(@egg.repo_path, "requirements.txt")

			FileUtils.cp(
				requirements_src,
				File.join(@egg.app_root, "requirements.txt")
			)
			FileUtils.cp(
				requirements_src,
				File.join(@egg.app_root, @egg.app_trunk, "requirements.txt")
			)
		end

		def link_app_python_if_not_linked
			unless system("#{python_command} -V 2>/dev/null")
				bin_dir = @egg.bin_dir
				unless File.directory?(bin_dir)
					FileUtils.mkdir_p(bin_dir)
				end
				case Gem::Platform::local.os
				when Enums::BoxOSes::MACOS
					FileUtils.ln_sf(
						BoxBox.which("python@#{@min_version}").first,
						File.join(bin_dir, python_command)
					)
				when Enums::BoxOSes::LINUX
					FileUtils.ln_sf(
						BoxBox.which("python3").first,
						File.join(bin_dir, python_command)
					)
				else
					raise "OS not configured for link_app_python_if_not_linked"
				end
			end
		end

		def python_command
			env_prefix = @egg.env_prefix.dup
			ArgChecker.env_prefix(env_prefix)
			"#{env_prefix}-python".downcase
		end

		def python_version
			if 
				system("#{python_command} -V >/dev/null 2>&1") \
				&& ENV["VIRTUAL_ENV"].zero?\
			then
				`#{python_command} -V`[/\d+\.\d+\.\d+/].split(".")
			elsif system("python3 -V >/dev/null 2>&1")
				`python3 -V`[/\d+\.\d+\.\d+/].split(".")
			elsif system("python -V >/dev/null 2>&1")
				`python -V`[/\d+\.\d+\.\d+/].split(".")
			else
				raise "No python version found"
			end
		end

		def is_installed_version_good?
			min_version = @min_version.split(".").take(2).map(&:to_i)
			installed_version = python_version.take(2).map(&:to_i)
			(installed_version <=> min_version) > -1
		end

		def create_py_env_in_dir(env_root=nil)
			BoxBox.path_append(@egg.bin_dir)
			link_app_python_if_not_linked
			requirements_path = File.join(
				@egg.app_root,
				@egg.app_trunk,
				"requirements.txt"
			)
			if env_root.zero?
				env_root = File.join(@egg.app_root, @egg.app_trunk)
			end
			py_env_dir = File.join(env_root, "#{@egg.file_prefix}")
			ArgChecker.path(py_env_dir)
			ArgChecker.path(requirements_path)
			system(
				python_command,
				"-m",
				"virtualenv",
				py_env_dir,
				exception: true
				)
			#this is to make some of my newer than checks work
			FileUtils.touch(py_env_dir)
			script = <<~CALL
				. '#{py_env_dir}/bin/activate' &&
				# #python_env
				# use regular python command rather mc-python
				# because #{python_command} still points to the homebrew location
				python -m pip install -r '#{requirements_path}'
			CALL
			system(script, exception: true)
		end

		def regen_lib_supports
			output_file = File.join(@generated_file_dir, "file_reference.py")
			@log&.puts("regen_lib_supports: #{output_file} ")
			input_dir = @egg.sql_scripts_src
			File.open(output_file, "w") do |out|
				out.write("####### This file is generated. #######\n")
				out.write("# edit regen_file_reference_file #\n")
				out.write("# in mc_dev_ops.sh and rerun\n")
				out.write("from enum import Enum\n\n")
				out.write("class SqlScripts(Enum):\n")
				hash_index_dir(input_dir).each do |file, enum_name, sha256_hash|
					line =\
						"\t#{enum_name} = (\n\t\t\"#{file}\",\n\t\t\"#{sha256_hash}\"\n\t)\n"
					@log&.write(line)
					out.write(line)
				end
				out.write("\n\t@property\n")
				out.write("\tdef file_name(self) -> str:\n")
				out.write("\t\treturn self.value[0]\n\n")
				out.write("\t@property\n")
				out.write("\tdef checksum(self) -> str:\n")
				out.write("\t\treturn self.value[1]\n")

			end
		end

		def libs_dest_dir(env_root)
			version = python_version
			File.join(
				env_root,
				@egg.file_prefix,
				"lib",
				"python#{version[0]}.#{version[1]}",
				"site-packages",
				@egg.lib_import
			)
		end

		def replace_lib_files
			regen_lib_supports
			env_root = File.join(@egg.app_root, @egg.app_trunk)
			FileHerder.copy_dir(
				@egg.lib_src,
				libs_dest_dir(env_root) 
			)

		end

		def create_py_env_in_app_trunk
			@log&.puts("create_py_env_in_app_trunk")
			sync_requirement_list
			create_py_env_in_dir
			replace_lib_files
		end

		def install_py_env_if_needed
			if ! File.exist?(py_env_activate_path)
				sync_requirement_list
				create_py_env_in_app_trunk
			else
				replace_lib_files
			end
		end

		def activate_env
			install_py_env_if_needed
			activate = py_env_activate_path.dup
			ArgChecker.path(activate)
			exec(". '#{activate}'")
		end

		def start_python
			install_py_env_if_needed
			activate = py_env_activate_path.dup
			ArgChecker.path(activate)
			exec(". '#{activate}' && python")
		end

		def run_python_script(script)
			install_py_env_if_needed
			activate = py_env_activate_path.dup
			ArgChecker.path(activate)
			BoxBox.run_and_get(". '#{activate}' && python /dev/stdin", in_s: script)
		end
	end
end