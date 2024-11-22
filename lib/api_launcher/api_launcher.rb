require "fileutils"
require_relative "../file_herder/file_herder"


module SaladPrep
	class APILauncher

		def initialize(egg, dbass, w_spoon current_user)
			@egg = egg
			@dbass = dbass
			@w_spoon = w_spoon
			@current_user = current_user
		end

		def setup_api_dir
			unless File.directory?(File.join(@egg.web_root, @egg.api_dest))
				FileUtils.mkdir_p(File.join(@egg.web_root, @egg.api_dest))
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
			@w_spoon.setup_nginx_confs
		end

		def startup_api(skip_setup:false)
			setup_api
		end

	end

end