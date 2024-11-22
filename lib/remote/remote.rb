require "resolv"
require "open3"
require "tempfile"
require "fileutils"
require_relative "../box_box/box_box"
require_relative "../brick_stack/brick_stack"
require_relative "../egg/egg"
require_relative "../resorcerer/resorcerer"
require_relative "../strink/strink"
require_relative "./tiny_remote"

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
			**rest
		)
			super(**rest)
			@api_launcher = api_launcher
			@client_launcher = client_launcher
		end

		def ruby_script
			"raise 'Remote Script Not implemented'"
		end

		def deploy

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
							#{ruby_script}
						EOF
					SCRIPT
				)
				file.rewind()
				puts(file.read)
			end
			# stdout_s, stderr_s, status = Open3.capture3(
			# 	"ssh -i #{@id_file} 'root@#{@ip_address}' ls"
			# )
			# puts("here #{status}")
			# puts(stderr_s.read)
			res = Open3.popen3(
				"ssh -i #{@id_file} 'root@#{@ip_address}' ls"
			) do |i, o, e, t|
				print("a?")
				i.puts 'ls'

				# print("b?")
				Thread.new do
					o.each {|l| puts l }
					o.close()
				end
				# Thread.new do
				# 	e.each {|l| puts l }
				# 	e.close
				# end
				
				print("c?")
				t.value
			end
			print(res)
			# if ! system("ssh -i #{@id_file} 'root@#{@ip_address}'")
			# 	puts("failed")
			# end
		end

		def is_ssh
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

		def remote_setup(setup_lvl, current_branch="main")
			if ! is_ssh
				raise "This section should only be run remotely"
			end

			if ! @egg.server_env_check
				puts("error with missing keys on server")
				return
			end

			brick_stack.create_install_directory

			if ! system("git --version", out: File::NULL, err: File::NULL)
				BoxBox::install_package("git")
			end

			FileUtils.rm_rf(@egg.repo_path)

			Dir.chdir(File.join(@gg.app_root, @egg.build_dir)) do 
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

			remote_setup_path

		end

		def self.fart()
			puts("pffttt")
		end

	end
end
