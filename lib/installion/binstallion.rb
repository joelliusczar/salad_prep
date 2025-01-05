require "fileutils"
require_relative "../box_box/box_box"
require_relative "../file_herder/file_herder"
require_relative "../method_marker/method_marker"
require_relative "../resorcerer/resorcerer"
require_relative "../extensions/string_ex"
require_relative "../loggable/loggable"

module SaladPrep
	class Binstallion
		using StringEx
		extend MethodMarker
		include Loggable
		
		def initialize(egg, template_context_path, ruby_version = "3.3.5")
			@egg = egg

			@ruby_version = ruby_version
			#this is the path to the app defined code	
			@template_context_path = template_context_path
		end

		def concat_actions(is_local:)
			actions_body = ""
			actions_body ^= refresh_procs
			begin
				marked = marked_methods(:sh_cmd)
				warning_log&.puts("No symbols") if marked.none?
				marked.each do |symbol|
					diag_log&.puts(symbol)
					next if symbol == :refresh_procs
					if is_local
						actions_body ^= send(symbol)
					else
						if method_attrs(symbol).include?(:remote)
							actions_body ^= send(symbol)
						else
							actions_body ^= body_builder(symbol) do
								action_body = <<~CODE
									puts("\#{cmd_name} is not available in this environment")
								CODE
							end
						end
					end
				end
			rescue => e
				error_log&.puts("Error while trying to create bin file.")
				error_log&.puts(e.backtrace * "\n")
				error_log&.puts(e.message)
			end
			actions_body
		end

		def install_bins
			FileHerder.empty_dir(@egg.dev_ops_bin)
			BoxBox.path_append(@egg.dev_ops_bin)
			provincial_path = File.join(@egg.dev_ops_bin, "provincial.rb")
			File.open(provincial_path, "w").write(
				File.open(@template_context_path).read
			)
			file_path = File.join(
				@egg.dev_ops_bin,
				"#{@egg.env_prefix.downcase}_dev"
			)
			File.open(file_path, "w").write(
				Resorcerer.bin_wrapper_template_compile(
					concat_actions(is_local: true)
				)
			)
			FileUtils.chmod("a+x", file_path)
		end

		def ruby_prelude
			<<~PRE
			require 'bundler/inline'

			gemfile do
				source "https://rubygems.org"

				gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
			end

			require "salad_prep"
			PRE
		end

		def body_builder(name, &block)
			<<~CODE
				@actions_hash["#{name}"] = lambda do |args_hash|
					cmd_name = "#{name}"
					bin_action_wrap(args_hash) do
						#{instance_eval(&block).split("\n") * "\n\t\t"}
					end
				end
			CODE
		end

		def self.def_cmd(name, &block)
			define_method(name) do
				body_builder(name, &block)
			end
		end

		def_cmd("refresh_procs") do
			action_body = <<~CODE
				Provincial.binstallion.install_bins
				puts("\#{Provincial::Canary.version}")
			CODE
		end

		def_cmd("install_py_env_if_needed") do
			action_body = <<~CODE
				Provincial.monty.install_py_env_if_needed
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("setup_client") do
			action_body = <<~CODE
				Provincial.client_launcher.setup_client
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("startup_api") do
			action_body = <<~CODE
				Provincial.api_launcher.startup_api
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("backup_db") do
			action_body = <<~CODE
				output_path = Provincial.dbass.backup_db(
					backup_lvl:args_hash["-backuplvl"]
				)
				puts("SQL dumped at '\#{output_path}'")
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("tape_db") do
			action_body = <<~CODE
				local_out_path = args_hash.coalesce("o", "out", "output")
				if local_out_path.zero?
					raise "Output path not provided"
				end


				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby #{@ruby_version}"
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
					#{ruby_prelude}
					\#{Provincial.egg.app_lvl_definitions_script}
					Provincial.egg.load_env
					out_path = Provincial.dbass.backup_db(
						backup_lvl: '\#{args_hash["-backuplvl"]}'
					)
					puts(out_path) #doesn't print to screen. This is returned
					EOF
				REMOTE
	
				remote_out_path = Provincial.remote.run_remote(remote_script).chomp
				puts("Remote path: \#{remote_out_path}")
				if remote_out_path.zero?
					raise "Server provided output path is blank."
				end
				Provincial.remote.grab_file(remote_out_path, local_out_path)
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("setup_db") do
			action_body = <<~CODE
				if args_hash["clean"].populated?
					Provincial.dbass.teardown_db(
						force: args_hash.include?("force", "-f")
					)
				end
				Provincial.dbass.setup_db
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("db_run") do
			action_body = <<~CODE
				Provincial.dbass.run_one_off($stdin)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("connect_root") do
			action_body = <<~CODE
				Provincial.remote.connect_root
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("empty_dir") do
			action_body = <<~CODE
				SaladPrep::FileHerder.empty_dir(args_hash[0])
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("env_hash") do
			action_body = <<~CODE
				prefer_keys_file = args_hash[0] != "local"
				Provincial.egg.env_hash(
					include_dirs: true,
					prefer_keys_file:
				).each do |k, v|
					puts("\"\#{k}\"=>\"\#{v}\"")
				end
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("egg") do
			action_body = <<~CODE
				prefer_keys_file = args_hash[0] != "local"
				puts(Provincial.egg.to_s(prefer_keys_file:))
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("install") do
			action_body = <<~CODE
				Provincial.installion.install_dependencies
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_install") do
			action_body = <<~CODE
				current_branch = args_hash["branch"]
				if current_branch.zero?
					current_branch = `git branch --show-current 2>/dev/null`.strip
				end
				Provincial.egg.load_env
				return unless Provincial.remote.pre_deployment_check(current_branch:)
				remote_script = Provincial.egg.env_exports
				remote_script ^= Provincial::Resorcerer.bootstrap_install
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
						#{ruby_prelude}
						require "salad_prep"
						\#{Provincial.egg.app_lvl_definitions_script}
						Provincial.box_box.setup_build
						Provincial.installion.install_dependencies
					EOF
				REMOTE
				Provincial.remote.run_remote(remote_script)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_api") do
			action_body = <<~CODE
				current_branch = args_hash["branch"]
				if current_branch.zero?
					current_branch = `git branch --show-current 2>/dev/null`.strip
				end
				Provincial.egg.load_env
				return unless Provincial.remote.pre_deployment_check(
					current_branch:,
					test_honcho: Provincial.test_honcho
				)
				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby #{@ruby_version}"
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
					#{ruby_prelude}
					\#{Provincial.egg.app_lvl_definitions_script}
					Provincial.egg.load_env
					Provincial.box_box.setup_build
					Provincial.api_launcher.startup_api
					EOF
				REMOTE
				Provincial.remote.run_remote(remote_script)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_client") do
			action_body = <<~CODE
				current_branch = args_hash["branch"]
				if current_branch.zero?
					current_branch = `git branch --show-current 2>/dev/null`.strip
				end
				Provincial.egg.load_env
				return unless Provincial.remote.pre_deployment_check(
					current_branch:,
					test_honcho: Provincial.test_honcho
				)
				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby #{@ruby_version}"
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
					#{ruby_prelude}
					\#{Provincial.egg.app_lvl_definitions_script}
					Provincial.egg.load_env
					Provincial.box_box.setup_build
					Provincial.client_launcher.setup_client
					EOF
				REMOTE
				Provincial.remote.run_remote(remote_script)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_snippet") do
			action_body = <<~CODE
				remote_script = args_hash[0]
				Provincial.egg.load_env
				puts(Provincial.remote.run_remote(remote_script))
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_files") do
			action_body = <<~CODE
				local_in_path = args_hash.coalesce("in", "input")
				if local_in_path.zero?
					raise "Input path not provided"
				end

				remote_out_path = args_hash.coalesce("o", "out", "output")
				if remote_out_path.zero?
					raise "Output path not provided"
				end

				Provincial.remote.push_files(
					local_in_path,
					remote_out_path,
					recursive: args_hash.include?("-r")
				)
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("deploy_procs") do
			action_body = <<~CODE
				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby #{@ruby_version}"
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
						=begin
							No access to Provincial in this remote script
						=end
						require "tempfile"
						#{ruby_prelude}
						egg = SaladPrep::Egg.new(
							project_name_0: "#{@egg.project_name_0}",
							repo_url: "#{@egg.repo_url}",
							env_prefix: "#{@egg.env_prefix}",
							url_base:  "#{@egg.url_base}",
							tld: "#{@egg.tld}",
							db_owner_name: "#{@egg.db_owner_name}",
						)

						SaladPrep::FileHerder.empty_dir(egg.dev_ops_bin)
						SaladPrep::BoxBox.path_append(egg.dev_ops_bin)
						puts(egg.dev_ops_bin)
					EOF
				REMOTE
				remote_path = Provincial.remote.run_remote(remote_script)
				Provincial.remote.push_files(
					"#{@template_context_path}",
					"#{remote_path}/provincial.rb",
				)
				gen_out_path = "#{remote_path}/#{@egg.env_prefix.downcase}_dev"
				Tempfile.create do |tmp|
					tmp.write(
						SaladPrep::Resorcerer.bin_wrapper_template_compile(
							Provincial.binstallion.concat_actions(is_local: false)
						)
					)
					Provincial.remote.push_files(
						tmp.path,
						gen_out_path,
					)
				end
				remote_script = Provincial.egg.env_exports
				remote_script ^= "asdf shell ruby #{@ruby_version}"
				remote_script ^= <<~REMOTE
					ruby <<'EOF'
						require "fileutils"
						FileUtils.chmod("a+x", "#{gen_out_path}")
					EOF
				REMOTE
			CODE
		end

		mark_for(:sh_cmd)
		def_cmd("connect_root") do
			action_body = <<~CODE
				Provincial.remote.connect_root
			CODE
		end

		mark_for(:sh_cmd, :remote)
		def_cmd("bundle_path") do
			action_body = <<~CODE
					git_hash = Provincial::BoxBox.run_and_get(
						"git",
						"ls-remote",
						Provincial::Canary.source_code_uri,
						exception: true
					).split.first[0,12]
					require "bundler"
					puts(
						"\#{Bundler.bundle_path.to_path}/bundler/gems/salad_prep-\#{git_hash}"
					)
			CODE
		end

	end
end