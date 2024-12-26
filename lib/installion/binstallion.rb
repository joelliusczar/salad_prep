require "fileutils"
require_relative "../box_box/box_box"
require_relative "../file_herder/file_herder"
require_relative "../resorcerer/resorcerer"
require_relative "../extensions/strink"

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
				actions_body ^= template_cmd_mapping(name, body)
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
			yield tape_db
			yield connect_root
			yield empty_dir
			yield env_hash
		end

		def template_cmd_mapping(name, body)
			<<~CODE
				@actions_hash["#{name}"] = lambda do |args_hash|
					bin_action_wrap(args_hash) do
						#{body.chomp}
					end
				end
			CODE
		end

		def install_py_env_if_needed
			action_body = <<~'CODE'
				Provincial.monty.install_py_env_if_needed
			CODE
			["install_py_env_if_needed", action_body]
		end

		def setup_client
			action_body = <<~'CODE'
				Provincial.client_launcher.setup_client
			CODE
			["setup_client", action_body]
		end

		def startup_api
			action_body = <<~'CODE'
				Provincial.api_launcher.startup_api
			CODE
			["startup_api", action_body]
		end

		def backup_db
			action_body = <<~'CODE'
				Provincial.dbass.backup_db
			CODE
			["backup_db", action_body]
		end

		def tape_db
			action_body = <<~'CODE'
				Provincial.remote.backup_db
			CODE
			["tape_db", action_body]
		end

		def connect_root
			action_body = <<~'CODE'
				Provincial.remote.connect_root
			CODE
			["connect_root", action_body]
		end

		def update_salad_prep
			action_body = <<~'CODE'
				system("bundle update")
			CODE
			["update_salad_prep", action_body]
		end

		def refresh_bins
			action_body = <<~'CODE'
				Provincial.binstallion.install_bins
			CODE
			["refresh_bins", action_body]
		end

		def empty_dir
			action_body = <<~'CODE'
				SaladPrep::FileHerder.empty_dir(args_hash[0])
			CODE
			["empty_dir", action_body]
		end

		def env_hash
			action_body = <<~'CODE'
				Provincial.egg.env_hash(include_dirs: true).each do |k, v|
					puts("\"#{k}\"=>\"#{v}\"")
				end
			CODE
			["env_hash", action_body]
		end

	end
end