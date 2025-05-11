require "fileutils"
require_relative "../../box_box/box_box"
require_relative "../../extensions/string_ex"
require_relative "./linux_spoon_handle"
require_relative "../../toob/toob"

module SaladPrep
	using StringEx

	class DebianSpoonHandle < LinuxSpoonHandle

		CERT_DIR = "/usr/local/share/ca-certificates"

		def install_local_cert(public_key_file_path)
			BoxBox.run_root_block do
				FileUtils.cp(
					public_key_file_path,
					CERT_DIR,
					verbose: true
				)
				system(
					"update-ca-certificates",
					exception: true
				)
			end
		end


		def remove_cert(cert_name, common_name)
			cert_dir = CERT_DIR
			if cert_name.zero?
				cert_name = common_name
			end
			cert_name.domain_name_check
			BoxBox.run_root_block do
				FileUtils.rm(
					Dir.glob("#{cert_dir}/#{cert_name}*.crt"),
					verbose: true
				)
				system(
					"update-ca-certificates",
					exception: true
				)
			end
		end


	end
end