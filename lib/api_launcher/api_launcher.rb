require "fileutils"
require_relative "../box_box/box_box"
require_relative "../file_herder/file_herder"


module SaladPrep
	class APILauncher

		def initialize(egg:, dbass:, w_spoon:)
			@egg = egg
			@dbass = dbass
			@w_spoon = w_spoon
		end

		def setup_api_dir
			unless File.directory?(@egg.api_dest)
				BoxBox.run_root_block do
					FileUtils.mkdir_p(@egg.api_dest)
				end
			end
		end

		def clean_up_running_processes
			BoxBox.kill_process_using_port(@egg.api_port)
		end

		def copy_api_files
			BoxBox.run_root_block do
				FileHerder::copy_dir(
					@egg.api_src, 
					@egg.api_dest
				)
			end
		end

		def copy_support_files
			FileHerder::copy_dir(
				@egg.templates_src, 
				@egg.template_dest
			)
		end

		def setup_api
			clean_up_running_processes
			setup_api_dir
			copy_api_files
			copy_support_files
			@dbass.setup_db
			@w_spoon.setup_nginx_confs(@egg.api_port.to_s)
		end

		def startup_api(skip_setup:false)
			setup_api
		end

	end

end