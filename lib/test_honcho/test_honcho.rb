require_relative "../file_herder/file_herder"
require_relative "../loggable/loggable"

module SaladPrep
	class TestHoncho
		include Loggable
	
		def initialize(egg:, dbass:, box_box:)
			@egg = egg
			@dbass = dbass
			@box_box = box_box
		end
	
	
		def setup_unit_test_env
			@egg.run_test_block do 
				publicKeyFile="#{@egg.get_debug_cert_path}.public.key.crt"
				@box_box.setup_app_directories
				FileHerder.copy_dir(@egg.templates_src, @egg.template_dest)
				@dbass.replace_sql_scripts
				@box_box.setup_env_api_file
			end
		end
	
		def run_unit_tests
			raise "run_unit_tests not implemented"
		end
	
	end
end