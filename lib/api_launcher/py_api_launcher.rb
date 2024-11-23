require_relative "./api_launcher"

module SaladPrep
	class PyApiLauncher < ApiLauncher


		def startup_api(skip_setup:false)
			super(skip_setup: skip_setup)
			py_activate = File.join(
				@egg.app_root, 
				@egg.app_trunk, 
				@egg.file_prefix,
				"bin",
				"activate"
			)
			app_dir = File.join(@egg.web_root, @egg.api_dest)
			unless File.exists?(py_activate)
				raise "#{py_activate} is not valid"
			end
			unless File.exists?(app_dir)
				raise "#{app_dir} is not valid"
			end
			unless @egg.port.is_a?(Integer)
				raise "#{port} is not valid"
			end
			script = <<~CALL
				. #{py_activate}/bin/activate
				uvicorn --app-dir #{app_dir} \
				--root-path /api/v1 \
				--host 0.0.0.0 \
				--port #{@egg.port} \
				"index:app" </dev/null >api.out 2>&1
			CALL
			pid = spawn(script)
			Process.detach(pid)
			puts(
				"Server base is #{Dir.pwd}. Look there for api.out and the log file"
			)
			puts("done starting up api. Access at #{@egg.full_url}")
		end
	end
end