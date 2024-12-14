require_relative "./enums"
require_relative "../strink/strink"

module SaladPrep
	using Strink

	class FarPort
		def initialize (
			egg:,
			api_launcher:,
			client_launcher:,
			installer:
		)
			@egg = egg
			@api_launcher = api_launcher
			@client_launcher = client_launcher
			@installer = installer
		end

		def is_ssh?
			! ENV["SSH_CONNECTION"].zero?
		end

		def remote_setup_path(setup_lvl)
			@egg.load_env
			case setup_lvl
			when Enums::SetupLvls::API
				@api_launcher.startup_api
			when Enums::SetupLvls::CLIENT
				@client_launcher.setup_client
			when Enums::SetupLvls::INSTALL
				@installer.install_dependencies
			else
				if block_given?
					yield
				else
					raise "Setup path not configured"
				end
			end
		end

	end
end