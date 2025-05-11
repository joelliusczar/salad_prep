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