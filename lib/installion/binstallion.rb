require "fileutils"
require_relative "../box_box/box_box"
require_relative "../file_herder/file_herder"
require_relative "../resorcerer/resorcerer"
require_relative "../strink/strink"

module SaladPrep
	using Strink

	class Binstallion
		def initialize(egg, template_context_path)
			@egg = egg

			#this is the path to the app defined code	
			@template_context_path = template_context_path
		end

		def install_bins
			FileHerder.empty_dir(@egg.dev_ops_bin)
			BoxBox.path_append(@egg.dev_ops_bin)
			provincial_path = File.join(@egg.dev_ops_bin, "provincial.rb")
			File.open(provincial_path, "w").write(
				File.open(@template_context_path).read
			)
			actions_body = ""
			build_actions do |name, body|
				actions_body ^= wrap_action(name, body)
			end
			file_path = File.join(
				@egg.dev_ops_bin,
				"#{@egg.env_prefix.downcase}_dev"
			)
			File.open(file_path, "w").write(
				Resorcerer.bin_wrapper_template_compile(
					actions_body
				)
			)
			FileUtils.chmod("a+x", file_path)
		end
		
		def build_actions
			yield update_salad_prep
			yield refresh_bins
			yield backup_db
			yield backup_remote_db
			yield connect_root
			yield empty_dir
		end

		def wrap_action(name, body)
			<<~CODE

				actions_hash["#{name}"] =  lambda do |args_hash|
					if args_hash.include?("testing")
						Provincial.egg.run_test_block do
							#{body}
						end
					else
						#{body}
					end
				end

			CODE
		end

		def install_py_env_if_needed
			action_body = <<~CODE
				Provincial.monty.install_py_env_if_needed
			CODE
			["install_py_env_if_needed", action_body]
		end

		def setup_client
			action_body = <<~CODE
				Provincial.client_launcher.setup_client
			CODE
			["setup_client", action_body]
		end

		def startup_api
			action_body = <<~CODE
				Provincial.api_launcher.startup_api
			CODE
			["startup_api", action_body]
		end

		def backup_db
			action_body = <<~CODE
				Provincial.dbass.backup_db
			CODE
			["backup_db", action_body]
		end

		def backup_remote_db
			action_body = <<~CODE
				Provincial.remote.backup_db
			CODE
			["backup_rmote_db", action_body]
		end

		def connect_root
			action_body = <<~CODE
				Provincial.remote.connect_root
			CODE
			["connect_root", action_body]
		end

		def update_salad_prep
			action_body = <<~CODE
				system("bundle update")
			CODE
			["update_salad_prep", action_body]
		end

		def refresh_bins
			action_body = <<~CODE
				Provincial.binstallion.install_bins
			CODE
			["refresh_bins", action_body]
		end

		def empty_dir
			action_body = <<~CODE
				SaladPrep::FileHerder.empty_dir(args_hash[0])
			CODE
			["empty_dir", action_body]
		end

	end
end