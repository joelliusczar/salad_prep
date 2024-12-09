require "resolv"
require "open3"
require "tempfile"
require "fileutils"
require_relative "../box_box/box_box"
require_relative "../egg/egg"
require_relative "./tiny_remote"
require_relative "../resorcerer/resorcerer"
require_relative "../strink/strink"

module SaladPrep
	using Strink

	class Remote < TinyRemote
		def initialize (
			egg,
			test_honcho
		)
			super(egg)
			@test_honcho = test_honcho
		end

		def ruby_script(setup_lvl, current_branch)
			"raise 'Remote Script Not implemented'"
		end

		def deploy(
			setup_lvl,
			current_branch:"main",
			skip_tests: false,
			update_salad_prep: false,
			print_env: false
		)
			@egg.load_env

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

			unless skip_tests
				@test_honcho.run_unit_tests
			end

			bootstrap_content = Resorcerer::bootstrap_compile(
				update_salad_prep: update_salad_prep
			)

			Tempfile.create do |file|
				env_exports = env_setup_script
				file.puts(env_exports)
				file.puts(bootstrap_content)
				file.puts(
					<<~SCRIPT
						ruby <<'EOF'
							#{ruby_script(setup_lvl, current_branch)}
						EOF
					SCRIPT
				)
				file.rewind
				if print_env
					print(env_exports)
				end
				system(
					"ssh -i #{@egg.ssh_id_file} 'root@#{@egg.ssh_address}' bash -s",
					in: file
				)
			end
	
		end
		
	end
end
