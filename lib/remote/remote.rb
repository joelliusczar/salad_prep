require "tempfile"
require "resolv"
require "tempfile"
require "fileutils"
require_relative "../box_box/box_box"
require_relative "../dbass/enums"
require_relative "../extensions/strink"
require_relative "../loggable/loggable"
require_relative "../resorcerer/resorcerer"



module SaladPrep
	using Strink

	class Remote
		include Loggable

		def initialize (egg)
			if ! File.file?(egg.ssh_id_file)
				raise "id file doesn't exist: #{egg.ssh_id_file}"
			end

			unless egg.ssh_address =~ Resolv::IPv6::Regex \
				|| egg.ssh_address =~ Resolv::IPv6::Regex\
			then
				raise "invalid ip address: #{egg.ssh_address}"
			end
			@egg = egg
		end

		def env_setup_script
			exports = ""
			@egg.env_hash.each_pair do |key, value|
				exports += "export #{key}='#{value}'; "
			end
			exports
		end

		def connect_root
			exec(
				"ssh",
				"-ti",
				@egg.ssh_id_file,
				"root@#{@egg.ssh_address}",
				env_setup_script,
				"bash",
				"-l"
			)
		end

		def connect_sftp_root
			exec(
				"sftp",
				"-6",
				"-i",
				@egg.ssh_id_file,
				"root@#{@egg.ssh_address}",
			)
		end

		def toot_check
			system(
				"ssh",
			 "-i",
			 @egg.ssh_id_file,
			 "toot@#{@egg.ssh_address}",
			 "-oBatchMode=yes",
			 "true"
			)
		end

		def setup_toot
			unless toot_check

			end
		end

		def run_remote(shell_content: nil, ruby_content: nil)
			script = ""
			env_exports = env_setup_script
			script ^= env_exports
			if shell_content.populated?
				script ^= shell_content
			else
				script ^= "asdf shell ruby 3.3.5"
			end
			if ruby_content.populated?
				script ^= <<~SCRIPT
					ruby <<'EOF'
						require 'bundler/inline'

						gemfile do
							source "https://rubygems.org"

							gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
						end

						require "salad_prep"
						#{ruby_content}
					EOF
				SCRIPT
			end
			diag_log&.write(script)
			BoxBox.run_and_get(
				"ssh",
				"-i",
				@egg.ssh_id_file,
				"root@#{@egg.ssh_address}",
				"bash",
				"-s",
				in_s: script,
				exception: true
			)
		end

		def app_lvl_definitions_script
			"raise 'app_lvl_definitions_script not implemented'"
		end

		def ruby_script(setup_lvl, current_branch)
			app_lvl_definitions_script ^ \
				"Provincial.remote_actions['#{setup_lvl}']()"
		end

		def pre_deployment_check(
			current_branch:nil,
			test_honcho: nil
		)
			if current_branch.zero?
				current_branch = `git branch --show-current 2>/dev/null`.strip
			end

			puts("Deployment environmental variable check")
			@egg.deployment_env_check_recommended.each do |e|
				puts("Recomended var #{e} not set")
			end
			
			required_env_vars = @egg.deployment_env_check_required.map do |e|
				"Required var #{e} not set"
			end

			if required_env_vars.any?
				raise required_env_vars.join("\n")
			end

			if ! `git status --porcelain`.zero?
				puts(
					"There are uncommited changes that will not be apart of the deploy"
				)
				puts("continue?")
				choice = gets.chomp
				if choice.upcase == "N"
					puts("Canceling action")
					return
				end
			end

			system("git fetch")

			if `git rev-parse @` != `git rev-parse @{u}`
				puts("remote branch may not have latest set of commits")
				puts("continue?")
				choice = gets.chomp
				if choice.upcase == "N"
					puts("Canceling action")
					return
				end
			end

			if test_honcho
				test_honcho.run_unit_tests
			end
		end

		def deploy(
			setup_lvl,
			current_branch:nil,
			test_honcho: nil,
			update_salad_prep: false,
			print_env: false
		)
			@egg.load_env

			pre_deployment_check(current_branch:, test_honcho:)

			bootstrap_content = Resorcerer.bootstrap

			run_remote(
				shell_content: bootstrap_content,
				ruby_content: ruby_script(setup_lvl, current_branch)
			)
	
		end

		def grab_file(src, dest)
			system(
				"scp",
				"-i",
				@egg.ssh_id_file,
				"root@#{@egg.ssh_address}:#{src}",
				dest,
				exception: true
			)
		end

		def backup_db(backup_path, backup_lvl: Enums::BackupLvl::ALL)
			content = <<~CODE
				#{app_lvl_definitions_script}
				Provincial.remote.class.run_remote_action do
					output_path = Provincial.dbass.backup_db(backup_lvl: '#{backup_lvl}')
					puts(output_path)
				end
			CODE
			output_path = run_remote(
				ruby_content: content
			).chomp
			grab_file(output_path, backup_path)
		end

		def self.is_ssh?
			! ENV["SSH_CONNECTION"].zero?
		end

		def self.run_remote_action
			if ! is_ssh?
				raise "This section should only be run remotely"
			end
			@egg.load_env
			yield
		end

		def run_remote_deployment_action(current_branch, brick_stack)
			if ! is_ssh?
				raise "This section should only be run remotely"
			end
			@egg.load_env
			required_env_vars = @egg.server_env_check_required.map do |e|
				"Required var #{e} not set"
			end

			if required_env_vars.any?
				raise required_env_vars.join("\n")
			end

			brick_stack.create_install_directory

			BoxBox.install_if_missing("git")

			FileUtils.rm_rf(@egg.repo_path)

			Dir.chdir(@egg.build_dir) do 
				system(
					"git", "clone", @egg.repo_url, @egg.project_name_snake,
					exception: true
				)
				Dir.chdir(@egg.project_name_snake) do
					if current_branch != "main"
						system(
							"git", "checkout", "-t" , "origin/#{current_branch}",
							exception: true
						)
					end
				end
			end

			yield

		end

	end
end