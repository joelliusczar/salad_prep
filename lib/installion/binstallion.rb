require "fileutils"
require_relative "../box_box/box_box"
require_relative "../file_herder/file_herder"
require_relative "../method_marker/method_marker"
require_relative "../resorcerer/resorcerer"
require_relative "../extensions/strink"
require_relative "../loggable/loggable"

module SaladPrep
	class Binstallion
		using Strink
		extend MethodMarker
		include Loggable
		
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
			actions_body ^= refresh_bins
			begin
				marked = marked_methods(:sh_cmd)
				warning_log&.puts("No symboles") if marked.none?
				marked.each do |symbol|
					diag_log&.puts(symbol)
					next if symbol == :refresh_bins
					actions_body ^= send(symbol)
				end
			rescue
				error_log&.puts("Error while trying to create bin file.")
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
			puts("#{Canary.version}")
		end

		def self.def_cmd(name)
			define_method(name) do
				<<~CODE
					@actions_hash["#{name}"] = lambda do |args_hash|
						bin_action_wrap(args_hash) do
							#{yield.chomp}
						end
					end
				CODE
			end
		end

		def_cmd("install_py_env_if_needed") do
			action_body = <<-'CODE'
				Provincial.monty.install_py_env_if_needed
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("setup_client") do
			action_body = <<-'CODE'
				Provincial.client_launcher.setup_client
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("startup_api") do
			action_body = <<-'CODE'
				Provincial.api_launcher.startup_api
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("backup_db") do
			action_body = <<-'CODE'
				output_path = Provincial.dbass.backup_db(
					backup_lvl:args_hash["-backuplvl"]
				)
				puts("SQL dumped at '#{output_path}'")
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("tape_db") do
			action_body = <<-'CODE'
				out_param = ["-o", "-out", "-output"]
					.filter{ |p| args_hash[p].zero? }
					.first
				if out_param.zero?
						raise "Output path not provided"
				end

				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby 3.3.5"
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
					require 'bundler/inline'
	
					gemfile do
						source "https://rubygems.org"
	
						gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
					end
	
					require "salad_prep"
					#{Provincial.egg.app_lvl_definitions_script}
					Provincial.egg.load_env
					output_path = Provincial.dbass.backup_db(
						backup_lvl: '#{args_hash["-backuplvl"]}'
					)
					puts(output_path)
					EOF
				REMOTE
	
				output_path = Provincial.remote.run_remote(remote_script).chomp
				Provincial.remote.grab_file(output_path, args_hash[out_param])
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("connect_root") do
			action_body = <<-'CODE'
				Provincial.remote.connect_root
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("update_salad_prep") do
			action_body = <<-'CODE'
				system("bundle update")
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("refresh_bins") do
			action_body = <<-'CODE'
				Provincial.binstallion.install_bins
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("empty_dir") do
			action_body = <<-'CODE'
				SaladPrep::FileHerder.empty_dir(args_hash[0])
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("env_hash") do
			action_body = <<-'CODE'
				Provincial.egg.env_hash(include_dirs: true).each do |k, v|
					puts("\"#{k}\"=>\"#{v}\"")
				end
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("egg") do
			action_body = <<-'CODE'
				puts(Provincial.egg.to_s)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("install") do
			action_body = <<-'CODE'
				Provincial.installion.install_dependencies
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_install") do
			action_body = <<-'CODE'
				current_branch = args_hash["branch"]
				if current_branch.zero?
					current_branch = `git branch --show-current 2>/dev/null`.strip
				end
				Provincial.egg.load_env
				Provincial.remote.pre_deployment_check(current_branch:)
				remote_script = Provincial.egg.env_exports
				remote_script ^= Provincial::Resorcerer.bootstrap_install
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
						require 'bundler/inline'
	
						gemfile do
							source "https://rubygems.org"
		
							gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
						end
		
						require "salad_prep"
						#{Provincial.egg.app_lvl_definitions_script}
						Provincial.brick_stack.setup_build
						Provincial.installion.install_dependencies
					EOF
				REMOTE
				Provincial.remote.run_remote(remote_script)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_api") do
			action_body = <<-'CODE'
				current_branch = args_hash["branch"]
				if current_branch.zero?
					current_branch = `git branch --show-current 2>/dev/null`.strip
				end
				Provincial.egg.load_env
				Provincial.remote.pre_deployment_check(
					current_branch:,
					test_honcho: Provincial.test_honcho
				)
				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby 3.3.5"
				remote_script ^= <<~REMOTE
						require 'bundler/inline'
	
						gemfile do
							source "https://rubygems.org"
		
							gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
						end
		
						require "salad_prep"
						#{Provincial.egg.app_lvl_definitions_script}
						Provincial.brick_stack.setup_build
						Provincial.api_launcher.startup_api
				REMOTE
				Provincial.remote.run_remote(remote_script)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_client") do
			action_body = <<-'CODE'
				current_branch = args_hash["branch"]
				if current_branch.zero?
					current_branch = `git branch --show-current 2>/dev/null`.strip
				end
				Provincial.egg.load_env
				Provincial.remote.pre_deployment_check(
					current_branch:,
					test_honcho: Provincial.test_honcho
				)
				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby 3.3.5"
				remote_script ^= <<~REMOTE
					require 'bundler/inline'

					gemfile do
						source "https://rubygems.org"
	
						gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
					end
	
					require "salad_prep"
					#{Provincial.egg.app_lvl_definitions_script}
					Provincial.brick_stack.setup_build
					Provincial.client_launcher.setup_client
				REMOTE
				Provincial.remote.run_remote(remote_script)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("connect_root") do
			action_body = <<-'CODE'
				Provincial.remote.connect_root
			CODE
		end

	end
end