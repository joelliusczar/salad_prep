module SaladPrep
	class TinyRemote
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

		def env_setup_script()
			exports = ""
			@egge.env_hash.each_pair do |key, value|
				exports << "export #{key}='#{value}'"
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

	end
end