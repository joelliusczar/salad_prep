require "fileutils"
require_relative "../arg_checker/arg_checker"
require_relative "../box_box/box_box"
require_relative "../box_box/enums"
require_relative "../file_herder/file_herder"
require_relative "../strink/strink"

module SaladPrep
	class Monty

		def initialize(egg, version = "3.9")
			@egg = egg
			@version = version
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
			ArgChecker.env_prefix(@egg.env_prefix)
			unless system("#{@egg.env_prefix}-python -V 2>/dev/null")
				bin_dir = File.join(@egg.app_root, @egg.bin_dir)
				unless File.directory?(bin_dir)
					FileUtils.mkdir_p(bin_dir)
				end
				case Gem::Platform::local.os
				when Enums::BoxOSes::MACOS
					FileUtils.ln_sf(
						BoxBox.which("python@#{@version}").first,
						File.join(bin_dir, "#{@egg.env_prefix}-python")
					)
				when Enums::BoxOSes::LINUX
					FileUtils.ln_sf(
						BoxBox.which("python3").first,
						File.join(bin_dir, "#{@egg.env_prefix}-python")
					)
				else
					raise "OS not configured for link_app_python_if_not_linked"
				end
			end
		end

		def python_version
			ArgChecker.env_prefix(@egg.env_prefix)
			if 
				system("#{@egg.env_prefix}-python -V >/dev/null 2>&1") \
				&& Strink.empty_s?(ENV["VIRTUAL_ENV"])\
			then
				`#{@egg.env_prefix}-python -V`[/\d+\.\d+\.\d+/].split(".")
			elsif system("python3 -V >/dev/null 2>&1")
				`python3 -V`[/\d+\.\d+\.\d+/].split(".")
			elsif system("python -V >/dev/null 2>&1")
				`python -V`[/\d+\.\d+\.\d+/].split(".")
			else
				raise "No python version found"
			end
		end

		def create_py_env_in_dir(env_root=nil)
			link_app_python_if_not_linked
			requirements_path = File.join(
				@egg.app_root,
				@egg.app_trunk,
				"requirements.txt"
			)
			if Strink.empty_s?(env_root)
				env_root = File.join(@egg.app_root, @egg.app_trunk)
			end
			py_env_dir = File.join(env_root, @egg.file_prefix)
			ArgChecker.path(py_env_dir)
			ArgChecker.path(requirements_path)
			system("#{@egg.env_prefix}-python", "-m", py_env_dir, exception: true)
			script = <<~CALL
				. `#{py_env_dir}/bin/activate` &&
				#this is to make some of my newer than checks work
				touch `#{py_env_dir}` &&
				# #python_env
				# use regular python command rather mc-python
				# because mc-python still points to the homebrew location
				python -m pip install -r '#{requirements_path}' &&
			CALL
			system(script, exception: true)
		end

		def regen_lib_supports
		end

		def libs_dest_dir(env_root)
			version = python_version
			File.join(
				env_root,
				@egg.file_prefix,
				lib,
				"python#{version[0]}.#{version[1]}",
				"site-packages"
			)
		end

		def replace_lib_files
			regen_lib_supports
			env_root = File.join(@egg.app_root, @egg.app_trunk)
			FileHerder.copy_dir(
				@egg.lib_src,
				File.join(libs_dest_dir(env_root), @egg.lib_import)
			)

		end

		def create_py_env_in_app_trunk
			sync_requirement_list
			create_py_env_in_dir
			replace_lib_files
		end

	end
end