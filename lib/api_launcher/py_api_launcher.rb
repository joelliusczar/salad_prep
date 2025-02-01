require "fileutils"
require_relative "./api_launcher"
require_relative "../libby/monty"
require_relative "../arg_checker/arg_checker"

module SaladPrep
	class PyAPILauncher < APILauncher

		def initialize(monty:, **rest)
			super(**rest)
			@monty = monty
		end


		def copy_support_files
			super
			@monty.sync_requirement_list
			@monty.create_py_env_in_app_trunk
		end

		def startup_api(skip_setup:false)
			super(skip_setup: skip_setup)
			py_activate = File.join(
				@egg.app_root, 
				@egg.app_trunk, 
				@egg.file_prefix,
				"bin",
				"activate"
			)
			app_dir = @egg.api_dest
			unless File.exist?(py_activate)
				raise "#{py_activate} is not valid"
			end
			unless File.exist?(app_dir)
				raise "#{app_dir} is not valid"
			end
			unless @egg.api_port.is_a?(Integer)
				raise "#{@egg.api_port} is not valid"
			end
			ArgChecker.api_version(@egg.api_version)
			api_out = File.open("api.out", "a")
			script = <<~CALL
				. #{py_activate}
				uvicorn --app-dir #{app_dir} \
				--root-path /api/#{@egg.api_version} \
				--host 0.0.0.0 \
				--port #{@egg.api_port} \
				"index:app"
			CALL
			pid = BoxBox.script_spawn(
				script,
				in: File::NULL,
				out: api_out,
				err: api_out
			)
			Process.detach(pid)
			puts(
				"Server base is #{Dir.pwd}. Look there for api.out and the log file"
			)
			puts("done starting up api. Access at #{@egg.full_url}")
		end
		
	end
end