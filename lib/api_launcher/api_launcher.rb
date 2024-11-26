require "fileutils"
require_relative "../file_herder/file_herder"


module SaladPrep
	class APILauncher

		def initialize(egg:, dbass:, w_spoon:)
			@egg = egg
			@dbass = dbass
			@w_spoon = w_spoon
		end

		def setup_api_dir
			unless File.directory?(File.join(@egg.web_root, @egg.api_dest_suffix))
				FileUtils.mkdir_p(File.join(@egg.web_root, @egg.api_dest_suffix))
			end
		end

		def clean_up_running_processes
		end

		def sync_utility_scripts
		end

		def copy_api_files
			FileHerder::copy_dir(
				@egg.api_src, 
				File.join(@egg.web_root, @egg.api_dest_suffix)
			)
		end

		def copy_support_files
			FileHerder::copy_dir(
				@egg.templates_src, 
				File.join(@egg.app_root, @egg.template_dest_suffix)
			)
		end

		def setup_api
			clean_up_running_processes
			setup_api_dir
			sync_utility_scripts
			copy_api_files
			copy_support_files
			@dbass.setup_db
			@w_spoon.setup_nginx_confs
		end

		def startup_api(skip_setup:false)
			setup_api
		end

	end

end