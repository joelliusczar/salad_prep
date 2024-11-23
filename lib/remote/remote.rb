require "resolv"
require "open3"
require "tempfile"
require "fileutils"
require_relative "../box_box/box_box"
require_relative "../brick_stack/brick_stack"
require_relative "../egg/egg"
require_relative "./tiny_remote"
require_relative "../resorcerer/resorcerer"
require_relative "../strink/strink"

module SaladPrep

	module SetupLvls
		INSTALL = "install"
		API = "api"
		CLIENT = "client"
		UPDATE_TOOLS = "update_tools"
	end

	class Remote < TinyRemote
		def initialize (
			api_launcher:,
			client_launcher:,
			brick_stack:,
			egg:,
		)
			@egg = egg
			@api_launcher = api_launcher
			@client_launcher = client_launcher
		end

		def is_ssh?
			! Strink::empty_s?(ENV["SSH_CONNECTION"])
		end

		def remote_setup_path(setup_lvl)
			case setup_lvl
			when SetupLvls.API
				@api_launcher.startup_api
			when SetupLvls.CLIENT
				@client_launcher.setup_client
			end
		end

		def ruby_script(setup_lvl, current_branch)
			"raise 'Remote Script Not implemented'"
		end



		def deploy(setup_lvl, current_branch="main")

			if ! Strink::empty_s(`git status --porcelain`)
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

			`git fetch`

			if `git rev-parse @` != `git rev-parse @{u}`
				puts("remote branch may not have latest set of commits")
				puts("continue?")
				choice = gets.chomp
				if choice.upcase == "N"
					puts("Canceling action")
					return
				end
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
