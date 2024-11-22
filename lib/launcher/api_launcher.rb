require_relative "../file_herder/file_herder"


module SaladPrep
	class APILauncher

		def initialize(egg, dbass, current_user)
			@egg = egg
			@dbass = dbass
			@current_user = current_user
		end

		def setup_api_dir
			unless File.directory?(File.join(@egg.web_root, @egg.api_dest))
				system(
					"sudo", "-p", "Pass required to create web server directory: ",
					"mkdir", "pv", File.join(@egg.web_root, @egg.api_dest)
					exception: true
				)
			end
		end

		def clean_up_running_processes
		end

		def copy_api_files
			FileHerder::copy_dir(
				@egg.templates_src, 
				File.join(@egg.app_root, @egg.template_dest_suffix),
				@current_user
			)
		end



		def setup_api
			clean_up_running_processes
			setup_api_dir
			copy_api_files
			@dbass.setup_db
			
		end

		def startup_api(skip_setup:false)

		end

	end

end