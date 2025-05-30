require "fileutils"
require_relative "../extensions/string_ex"
require_relative "./test_honcho"
require_relative "../toob/toob"

module SaladPrep
	class PyTestHoncho < TestHoncho
		using StringEx

		def initialize(monty:, **rest)
			super(**rest)
			@monty = monty
		end

		def setup_unit_test_env(overrides = {})
			super(overrides.merge({
				"PYTHONPATH" => "#{@egg.src}:#{@egg.src}/api:#{@egg.src}/tests",
				"#{@egg.env_prefix}_APP_ROOT" => @egg.app_root
			}))
			py_env_path = @monty.py_env_path
			src_files = Dir.glob(
				"**/*",
				File::FNM_DOTMATCH,
				base: @egg.lib_src
			)
			requirements_src = File.join(
				@egg.repo_fixed_path,
				"requirements.txt"
			)
			if 
				! FileUtils.uptodate?(py_env_path, src_files)\
				|| ! FileUtils.uptodate?(py_env_path, [requirements_src])\
			then
				@monty.create_py_env_in_app_trunk
			else
				Toob.log&.puts("Skipping create_py_env_in_app_trunk")
			end
		end

		def run_unit_tests
			@egg.run_test_block do
				setup_unit_test_env
				py_activate = @monty.py_env_activate_path

				py_activate.path_check
				script = <<~CALL
					. '#{py_activate}' &&
					pytest -s
				CALL
				Dir.chdir(File.join(@egg.src, "tests")) do 
					BoxBox.script_run({ #this hash may not be needed anymore
						"PYTHONPATH" => "#{@egg.src}:#{@egg.src}/api:#{@egg.src}/tests",
						"#{@egg.env_prefix}_APP_ROOT" => @egg.app_root
						}, 
						script,
						exception: true
					)
				end
			end
		end

	end
end