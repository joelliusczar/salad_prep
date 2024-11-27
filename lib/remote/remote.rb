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

		def deploy(setup_lvl, current_branch="main", skip_tests: false)

			if ! Strink.empty_s?(`git status --porcelain`)
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

			if system("git rev-parse @` != `git rev-parse @{u}")
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

			Tempfile.create do |file|
				file.write(env_setup_script())
				file.write(Resorcerer::bootstrap)
				file.write(
					<<~SCRIPT
						ruby <<EOF
							#{ruby_script(setup_lvl, current_branch)}
						EOF
					SCRIPT
				)
				file.rewind
				system("ssh -i #{@id_file} 'root@#{@ip_address}' bash -s", in: file)
			end
	
		end
		
	end
end
