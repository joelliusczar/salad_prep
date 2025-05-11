require "base64"
require_relative "../cert_info"
require_relative "../../extensions/string_ex"
require_relative "./unix_spoon_handle"

module SaladPrep
	class LinuxSpoonHandle < UnixSpoonHandle
		using StringEx

		def ssh_dir
			File.join(@egg.app_root,".ssh")
		end


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


		def extract_enddate_from_cert(cert)
			output = IO.popen(["openssl", "x509", "-enddate"], "r+") do |p|
				p.write(cert)
				p.close_write
				p.read
			end
			output[/notAfter *= *([a-zA-Z0-9: ]+)/,1]
		end


		def certs_matching_name(common_name)
			scan_pems_file_for_common_name(
					common_name,
					"/etc/ssl/certs/ca-certificates.crt"
				)
		end


		def openssl_default_conf
			"/etc/ssl/openssl.cnf"
		end

	end
end