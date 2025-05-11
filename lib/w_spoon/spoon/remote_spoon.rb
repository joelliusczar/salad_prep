require_relative "../../toob/toob"
require_relative "./where_spoon"

module SaladPrep
	class RemoteSpoon < WhereSpoon

		def initialize(egg, spoon_handle, cert_retriever)
			@egg = egg
			@cert_retriever = cert_retriever
			@spoon_handle = spoon_handle
		end


		def public_key
			"/etc/ssl/certs/#{@egg.project_name_snake}.public.key.pem"
		end


		def private_key
			"/etc/ssl/private/#{@egg.project_name_snake}.private.key.pem"
		end


		def cert_chain_key
			""
		end


		def setup_ssl_certs(force_replace: false)
			public_key_file_path = "#{public_key}"
			private_key_file_path = "#{private_key}"
			certificate_chain_file_path = cert_chain_key
			if ! File.file?(public_key_file_path) \
				|| !File.file?(private_key_file_path)\
				|| @spoon_handle.is_cert_expired(File.open(public_key_file_path).read)\
				|| force_replace
			then
				Toob.log&.puts("downloading new certs")
				cert_keys = @cert_retriever.ssl_vars
				File.open(private_key_file_path, "w")
					.write(cert_keys.private_key)
				File.open(public_key_file_path, "w")
					.write(cert_keys.public_key)
				#does not appear to be used
				# File.open(certificate_chain_file_path, "w")
				# 	.write(cert_hash["certificatechain"].chomp)
			end
		end

	end
end