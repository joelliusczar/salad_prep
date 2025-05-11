require_relative "../toob/toob"
require_relative "./spoon/local_spoon"
require_relative "./spoon/remote_spoon"
require_relative "./spoon_handle/mac_spoon_handle"
require_relative "./spoon_handle/debian_spoon_handle"

module SaladPrep

	class WSpoon

		def initialize(egg, where_spoon, spoon_phone)
			@egg = egg
			@where_spoon = where_spoon
			@spoon_phone = spoon_phone
		end


		def self.spoon_handle(egg)
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				MacSpoonHandle.new(egg)
			when Enums::BoxOSes::LINUX
				if File.file?("/etc/debian_version")
					DebianSpoonHandle.new(egg)
				else
					raise "Linux variant not setup"
				end
			else
				raise "Not implemented for #{Gem::Platform::local.os}"
			end
		end


		def restart_server
			@spoon_phone.restart_server
		end


		def refresh_certs
			@where_spoon.setup_ssl_certs
			@spoon_phone.restart_server
		end


		def setup_server_confs(port)
			@where_spoon.setup_ssl_certs
			@spoon_phone.setup_confs(port)
			@spoon_phone.restart_server
		end


		def startup_server_for_debug
			setup_server_confs(@egg.test_port.to_s)
			@spoon_phone.restart_server
		end


		def server_config_path
			@spoon_phone.main_config_path
		end

	end
end
