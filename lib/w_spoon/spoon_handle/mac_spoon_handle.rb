require_relative "../../box_box/box_box"
require_relative "../../toob/toob"
require_relative "./unix_spoon_handle"

module SaladPrep
	class MacSpoonHandle < UnixSpoonHandle

		def keychain_osx
			"/Library/Keychains/System.keychain"
		end

		def ssh_dir
			File.join(@egg.app_root,".ssh")
		end

		def certs_matching_name(common_name)
			unless /[a-zA-Z0-9\.\-_]+/ =~ common_name
				raise "Common name has illegal characters"
			end
			`security find-certificate -a -p -c #{common_name} #{keychain_osx}`
		end


		def remove_cert(cert_name, common_name)
			sha_256_value = extract_sha256_from_cert(cert)
			BoxBox.run_root_block do
				system(
					"security", "delete-certificate",
					"-z", sha_256_value, "-t", keychain_osx,
					exception: true
				)
			end
		end


		def install_local_cert(public_key_file_path)
			BoxBox.run_root_block do
				system(
					"security", "add-trusted-cert", "-p",
					"ssl", "-d", "-r", "trustRoot",
					"-k", keychain_osx, public_key_file_path,
					exception: true
				)
			end
		end


		def openssl_default_conf
			"/System/Library/OpenSSL/openssl.cnf"
		end

	end
end