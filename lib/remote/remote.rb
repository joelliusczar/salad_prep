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

		def connect_root
			exec(
				"ssh",
				"-ti",
				@egg.ssh_id_file,
				"root@#{@egg.ssh_address}",
				@egg.env_exports,
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

		def run_remote(script)
			diag_log&.write(script)
			BoxBox.run_and_get(
				"ssh",
				"-i",
				@egg.ssh_id_file,
				"root@#{@egg.ssh_address}",
				"bash",
				"-sl",
				in_s: script,
				exception: true
			)
		end

		def deployment_vars_check
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
		end

		def unmerged_check
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
		end

		def pre_deployment_check(
			current_branch:nil,
			test_honcho: nil
		)
			if current_branch.zero?
				current_branch = `git branch --show-current 2>/dev/null`.strip
			end

			deployment_vars_check

			unmerged_check

			if test_honcho
				test_honcho.run_unit_tests
			end
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

		def self.is_ssh?
			! ENV["SSH_CONNECTION"].zero?
		end		

	end
end