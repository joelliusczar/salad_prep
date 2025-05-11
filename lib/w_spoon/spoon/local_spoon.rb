require_relative "../../box_box/box_box"
require_relative "./where_spoon"

module SaladPrep
	class LocalSpoon < WhereSpoon

		def initialize(egg, browser_trust_introducer, spoon_handle)
			@egg = egg
			@browser_trust_introducer = browser_trust_introducer
			@spoon_handle = spoon_handle
		end


		def cert_name
			"#{@egg.project_name_snake}_localhost_nginx"
		end


		def cert_path
			File.join(@spoon_handle.ssh_dir, cert_name)
		end


		def cert_name_debug
			"#{@egg.project_name_snake}_localhost_debug"
		end


		def cert_path_debug
			File.join(@spoon_handle.ssh_dir, cert_name_debug)
		end


		def public_key
			"#{cert_path}.public.key.crt"
		end


		def private_key
			"#{cert_path}.private.key.pem"
		end


		def any_certs_matching_name_exact(common_name)
			@spoon_handle.certs_matching_name(common_name).any? do |cert|
				@spoon_handle.extract_common_name_from_cert(cert) == common_name
			end
		end


		def setup_ssl_certs(force_replace: false)
			domain = @egg.domain_name
			@spoon_handle.add_test_url_to_hosts(domain)
			public_key_file_path = "#{cert_path}.public.key.crt"
			private_key_file_path = "#{cert_path}.private.key.pem"
			@spoon_handle.clean_up_invalid_certs(domain, cert_path)
			if ! any_certs_matching_name_exact(domain)
				@spoon_handle.setup_ssl_cert_local(
					domain,
					domain,
					public_key_file_path,
					private_key_file_path
				)
			end
			@browser_trust_introducer.introduce_public_key(public_key_file_path)
		end


		def setup_client_env_debug
			env_file = File.join(@egg.client_src, ".env.local")
			File.open(env_file, "w") do |f|
				f.puts("VITE_API_VERSION=#{@egg.api_version}")
				f.puts("VITE_BASE_ADDRESS=https://localhost:#{@egg.test_port}")
				#VITE_SSL_PUBLIC, and SSL_KEY_FILE are used by create-react-app
				#when calling `npm start`
				f.puts("VITE_SSL_PUBLIC=#{cert_path_debug}.public.key.crt")
				f.puts("VITE_SSL_PRIVATE=#{cert_path_debug}.private.key.pem")
			end
		end


		def setup_ssl_cert_local_debug
			public_key_file_path = "#{cert_path_debug}.public.key.crt"
			private_key_file_path = "#{cert_path_debug}.private.key.pem"
			@spoon_handle.clean_up_invalid_certs("#{@egg.app}-localhost")
			@spoon_handle.setup_ssl_cert_local(
				"#{@egg.app}-localhost",
				"localhost",
				public_key_file_path,
				private_key_file_path
			)
			@browser_trust_introducer.introduce_public_key(public_key_file_path)
			setup_client_env_debug
		end

	end
end