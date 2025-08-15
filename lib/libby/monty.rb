require "fileutils"
require "tempfile"
require_relative "../box_box/box_box"
require_relative "../box_box/enums"
require_relative "../extensions/array_ex"
require_relative "../extensions/string_ex"
require_relative "../file_herder/file_herder"
require_relative "./libby"
require_relative "../toob/toob"

module SaladPrep
	using ArrayEx
	using StringEx

	class Monty < Libby

		attr_reader :min_version

		def initialize(
			egg,
			min_version:"3.9",
			generated_file_dir: nil,
			replace_lib_files: true
		)
			@egg = egg
			@min_version = min_version
			raise "generated_file_dir is required" if generated_file_dir.zero?
			@generated_file_dir = generated_file_dir
			@replace_lib_files = replace_lib_files
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
			env_prefix.env_prefix_check
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
			installed_version.ge(min_version)
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
			py_env_dir.path_check
			requirements_path.path_check
			system(
				python_command,
				"-m",
				"virtualenv",
				py_env_dir,
				exception: true
			)
			should_install_requirements = @replace_lib_files ? 'yes': ''
			#this is to make some of my newer than checks work
			FileUtils.touch(py_env_dir)
			script = <<~CALL
				. '#{py_env_dir}/bin/activate' &&
				# #python_env
				# use regular python command rather the prefixed python
				# because #{python_command} still points to the homebrew location
				python -m ensurepip --upgrade
				python -m pip install --upgrade setuptools
				if [ -n '#{should_install_requirements}' ]; then
					python -m pip install -r '#{requirements_path}'
				else
					echo 'No dependencies were installed'
				fi
			CALL
			BoxBox.script_run(script, exception: true)
		end

		def regen_lib_supports
			output_file = File.join(@generated_file_dir, "file_reference.py")
			Toob.log&.puts("regen_lib_supports: #{output_file} ")
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
					Toob.diag&.write(line)
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
			Toob.log&.puts("create_py_env_in_app_trunk")
			sync_requirement_list if @replace_lib_files
			create_py_env_in_dir
			replace_lib_files if @replace_lib_files
		end

		def install_py_env_if_needed
			if ! File.exist?(py_env_activate_path)
				sync_requirement_list if @replace_lib_files
				create_py_env_in_app_trunk
			else
				replace_lib_files if @replace_lib_files
			end
		end

		def activate_env
			install_py_env_if_needed
			activate = py_env_activate_path.dup
			activate.path_check
			exec(". '#{activate}'")
		end

		def start_python
			@egg.load_env
			install_py_env_if_needed
			activate = py_env_activate_path.dup
			activate.path_check
			exec(". '#{activate}' && python")
		end

		def run_python_script(script, exception: true)
			Toob.diag&.puts("### run_python_script ###")
			@egg.load_env
			install_py_env_if_needed
			activate = py_env_activate_path.dup
			activate.path_check
			BoxBox.script_run("echo 'before py 1'; . '#{activate}' && python /dev/stdin", 
				in_s: "print('py check line 1')\nprint('py check line 2')",
				exception:
			)
			BoxBox.script_run("echo 'before py 2'; . '#{activate}' && python /dev/stdin", 
				in_s: script,
				exception:
			)
		end
	end
end