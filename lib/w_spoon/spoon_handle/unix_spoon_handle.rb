require "open3"
require "tempfile"
require_relative "../../box_box/box_box"
require_relative "./os_spoon_handle"

module SaladPrep
	class UnixSpoonHandle < OSSpoonHandle


		def scan_pems_file(certs_file)
			cert = "".b
			lines = File.open(certs_file, "rb").readlines
			Enumerator.new do |yielder|
				lines.map(&:chomp).each do |line|
					next if line == "-----BEGIN CERTIFICATE-----".b
					if line == "-----END CERTIFICATE-----".b
						decoded = Base64.decode64(cert)
						cert = "-----BEGIN CERTIFICATE-----\n".b \
						+ cert \
						+ "-----END CERTIFICATE-----".b

						yielder << cert
						cert = "".b
						next
					end
					cert += (line + "\n".b)
				end
			end
		end


		def scan_pems_file_for_common_name(common_name, certs_file)
			scan_pems_file(certs_file).filter do |cert|
				subject = extract_subject_from_cert(cert)
				/CN *= *#{common_name}/ =~ subject
			end
		end


		def pems_to_objs(certs_file)
			scan_pems_file(certs_file).lazy.map do |cert|
				CertInfo.new(
					extract_common_name_from_cert(cert),
					extract_enddate_from_cert(cert)
				)
			end
		end


		def add_test_url_to_hosts(domain)
			in_hosts = File.open("/etc/hosts") do |file| 
				file.any?{|l| l.include?(domain) }
			end
			unless in_hosts
				unless /[a-zA-Z0-9\-_\.]+-local\.[a-zA-Z0-9\.]/ =~ domain
					raise "#{domain} is not a valid local url"
				end
				BoxBox.run_root_block do
					File.open("/etc/hosts", "a").write("127.0.0.1\t#{domain}\n")
				end
			end
		end


		def extract_sha256_from_cert(cert)
			IO.popen(
				["openssl", "x509", "-fingerprint", "-sha256"],
				"r+"
			) do |p|
				p.write(cert)
				p.close_write
				output = p.read
				output[/(?:SHA|sha)256 Fingerprint=([A-Za-z0-9:]+)/,1].tr(":","")
			end
		end


		def extract_subject_from_cert(cert)
			IO.popen(["openssl", "x509", "-subject"], "r+") do |p|
				p.write(cert)
				p.close_write
				p.read
			end
		end


		def extract_enddate_from_cert(cert)
			output = IO.popen(["openssl", "x509", "-enddate"], "r+") do |p|
				p.write(cert)
				p.close_write
				p.read
			end
			output[/notAfter *= *([a-zA-Z0-9: ]+)/,1]
		end


		def is_cert_expired?(cert)
			_, status = Open3.capture2(
				"openssl x509 -checkend 3600 -noout",
				stdin_data: cert
			)
			status.exitstatus == 0 ? false : true
		end

		def cert_matches_common_name?(cert, common_name)
			extracted_common_name = extract_common_name_from_cert(cert)
			extracted_common_name == common_name
		end


		def openssl_default_conf
			raise "openssl_default_conf not implemented"
		end


		def openssl_gen_cert(
			common_name,
			domain,
			public_key_file_path,
			private_key_file_path
		)
			Tempfile.create do |tmp|
				tmp.write(File.open(openssl_default_conf).read)
				tmp.write("[SAN]\nsubjectAltName=DNS:#{domain},IP:127.0.0.1")
				tmp.rewind
				system(
					"openssl", "req","-x509", "-sha256", "-new", "-nodes", "-newkey",
					"rsa:2048", "-days", "7",
					"-subj", "/C=US/ST=CA/O=fake/CN=#{common_name}",
					"-reqexts", "SAN", "-extensions", "SAN",
					"-config", tmp.path, 
					"-keyout", private_key_file_path, "-out", public_key_file_path,
					exception: true
				)
			end
		end


		def install_local_cert(public_key_file_path)
			raise "install_local_cert not implemented"
		end


		def setup_ssl_cert_local(
			common_name,
			domain,
			public_key_file_path,
			private_key_file_path
		)
			openssl_gen_cert(
				common_name, 
				domain, 
				public_key_file_path, 
				private_key_file_path
			)
			install_local_cert(public_key_file_path)
		end



	end
end