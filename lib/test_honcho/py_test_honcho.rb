require_relative "./test_honcho"

module SaladPrep
	class PyTestHoncho < TestHoncho

		def run_unit_tests
			setup_unit_test_env
			@egg.run_test_block do
				py_activate = File.join(
					@egg.app_root, 
					@egg.app_trunk, 
					@egg.file_prefix,
					"bin",
					"activate"
				)
				api_key = @egg.api_auth_key
				
			end
		end

	end
end