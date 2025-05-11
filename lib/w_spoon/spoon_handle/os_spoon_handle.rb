require_relative "../../toob/toob"

module SaladPrep
	class OSSpoonHandle

		def initialize(egg)
			@egg = egg
		end


		def ssh_dir
			raise "ssh_dir not implemented"
		end


		def setup_ssl_cert_local(
			common_name,
			domain,
			public_key_file_path,
			private_key_file_path
		)
			raise "setup_ssl_cert_local not implemented"
		end


		def add_test_url_to_hosts(domain)
			raise "add_test_url_to_hosts not implemented"
		end


		def is_cert_expired(cert)
			raise "is_cert_expired not implemented"
		end


		def certs_matching_name(common_name)
			raise "certs_matching_name not implemented"
		end


		def extract_subject_from_cert(cert)
			raise "extract_subject_from_cert not implemented"
		end


		def extract_common_name_from_cert(cert)
			output = extract_subject_from_cert(cert)
			output[%r{CN *= *([^/\n]+)},1]
		end


		def clean_up_invalid_certs(common_name, cert_name = nil)
			Toob.log&.puts("common name: #{common_name}")
			Toob.log&.puts("cert name: #{cert_name}")
			certs_matching_name(common_name).each do |cert|
				if is_cert_expired(cert)
					Toob.log&.puts("A cert is expired for #{common_name}")
					remove_cert(cert_name, common_name)
				end
			end
		end


		def remove_cert(cert_name, common_name)
			raise "remove_cert not implemented"
		end

	end
end