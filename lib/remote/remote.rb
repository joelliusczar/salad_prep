require "resolv"
require "open3"
require "tempfile"
require "fileutils"
require_relative "../egg/egg"
require_relative "../strink/strink"
require_relative "../brick_stack/brick_stack"
require_relative "../resorcerer/resorcerer"
require_relative "../box_box/box_box"

module SaladPrep

	module SetupLvls
		INSTALL = "install"
		API = "api"
		CLIENT = "client"
	end

	class Remote
		def initialize (
			ipAddress,
			idFile,
			egg,
			brick_stack
		)
			if ! File.file?(idFile)
				raise "id file doesn't exist: #{idFile}"
			end

			unless ipAddress =~ Resolv::IPv6::Regex || ipAddress =~ Resolv::IPv6::Regex
				raise "invalid ip address: #{ipAddress}"
			end
			@ipAddress = ipAddress
			@idFile = idFile
			@egg = egg
		end

		def env_setup_script()
			<<~SCRIPT
			export PB_SECRET='#{@egg.pb_secret}'
			export PB_API_KEY='#{@egg.pb_api_key}'
			export #{@egg.env_prefix}_AUTH_SECRET_KEY='#{@egg.api_auth_key}'
			export #{@egg.env_prefix}_NAMESPACE_UUID='#{@egg.namespace_uuid}'
			export #{@egg.env_prefix}_DATABASE_NAME='#{@egg.project_name_snake}_db'
			export #{@egg.env_prefix}_DB_PASS_SETUP='#{@egg.db_setup_key}'
			export #{@egg.env_prefix}_DB_PASS_OWNER='#{@egg.db_owner_key}'
			export #{@egg.env_prefix}_DB_PASS_API='#{@egg.api_db_user_key}'
			export #{@egg.env_prefix}_DB_PASS_JANITOR='#{@egg.janitor_db_user_key}'
			export #{@egg.env_prefix}_API_LOG_LEVEL='#{@egg.api_log_level}'
			SCRIPT
		end

		def ruby_script
			"raise 'Remote Script Not implemented'"
		end

		def deploy()

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
			# 	"ssh -i #{@idFile} 'root@#{@ipAddress}' ls"
			# )
			# puts("here #{status}")
			# puts(stderr_s.read)
			res = Open3.popen3(
				"ssh -i #{@idFile} 'root@#{@ipAddress}' ls"
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
			# if ! system("ssh -i #{@idFile} 'root@#{@ipAddress}'")
			# 	puts("failed")
			# end
		end

		def is_ssh
			! Strink::empty_s?(ENV["SSH_CONNECTION"])
		end

		def remote_setup_path(setup_lvl)
			case setup_lvl
			when SetupLvls.API
				
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
							"git", "checkout", "-t" , "origin/#{current_branch}"
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
