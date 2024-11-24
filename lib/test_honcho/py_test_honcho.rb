require "fileutils"
require_relative "./test_honcho"

module SaladPrep
	class PyTestHoncho < TestHoncho

		def initialize(monty: **rest)
			super(**rest)
			@monty = monty
		end

		def setup_unit_test_env
			super
			py_env_path = File.join(
				@egg.app_root,
				@egg.app_trunk,
				@egg.file_prefix
			)
			src_files = Dir.glob(
				"**/*",
				File::FNM_DOTMATCH,
				base: @egg.lib_src
			)
			requirements_src = File.join(
				@egg.repo_path,
				"requirements.txt"
			)
			if 
				! FileUtils.uptodate?(py_env_path, src_files)\
				|| ! FileUtils.uptodate?(py_env_dir, [requirements_src])\
			then
				@monty.create_py_env_in_app_trunk
			end
		end

		def run_unit_tests
			@egg.run_test_block do
				setup_unit_test_env
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