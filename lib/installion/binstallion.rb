require "fileutils"
require_relative "../box_box/box_box"
require_relative "../file_herder/file_herder"
require_relative "../resorcerer/resorcerer"

module SaladPrep
	class Binstallion
		def initialize(egg, template_context_path)
			@egg = egg
			@template_context_path = template_context_path
		end

		def install_bins
			FileHerder.empty_dir(@egg.dev_ops_bin)
			BoxBox.path_append(@egg.dev_ops_bin)
		end

		def install_script(name, action_body)
			file_path = File.join(@egg.dev_ops_bin, name)
			File.open(file_path, "w").write(
				Resorcerer.bin_wrapper_template_compile(
					File.open(@template_context_path).read,
					action_body
				)
			)
			FileUtils.chmod("a+x", file_path)
		end

		def install_py_env_if_needed
			action_body = <<~CODE
				if args_hash.include?("testing")
					Provincial.egg.run_test_block do
						Provincial.monty.install_py_env_if_needed
					end
				else
					Provincial.monty.install_py_env_if_needed
				end
			CODE
			install_script(
				"#{@egg.env_prefix}install_py_env_if_needed",
				action_body
			)
		end

	end
end