require_relative "../file_herder/file_herder"

module SaladPrep
	class TestHoncho
	
		def initialize(egg:, dbass:, brick_stack:)
			@egg = egg
			@dbass = dbass
			@brick_stack = brick_stack
		end
	
	
		def setup_unit_test_env
			@egg.run_test_block do 
				publicKeyFile="#{@egg.get_debug_cert_path}.public.key.crt"
				@brick_stack.setup_app_directories
				@brick_stack.generate_initial_keys_file
				FileHerder.copy_dir(@gg.templates_src, @egg.template_dest_suffix)
				@dbass.replace_sql_scripts
				@brick_stack.setup_env_api_file
			end
		end
	
		def run_unit_tests
			raise "run_unit_tests not implemented"
		end
	
	end
end