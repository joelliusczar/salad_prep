module SaladPrep
	class TinyRemote
		def initialize (
			ip_address:,
			id_file:,
			egg:
		)
			if ! File.file?(id_file)
				raise "id file doesn't exist: #{id_file}"
			end

			unless ip_address =~ Resolv::IPv6::Regex || ip_address =~ Resolv::IPv6::Regex
				raise "invalid ip address: #{ip_address}"
			end
			@ip_address = ip_address
			@id_file = id_file
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

		def connect_root
			exec(
				"ssh",
				"-ti",
				@id_file,
				"root@#{@egg.ssh_address}",
				env_setup_script,
				"bash",
				"-l"
			)
		end

		def toot_check
			system("ssh -i #{@id_file} 'toot@#{@ip_address}' -oBatchMode=yes true")
		end

		def setup_toot
			unless toot_check

			end
		end

	end
end