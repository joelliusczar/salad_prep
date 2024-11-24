require_relative "./enums"
require_relative "../strink/strink"

module SaladPrep
	class FarPort
		def initialize (
			egg:,
			api_launcher:,
			client_launcher:
		)
			@egg = egg
			@api_launcher = api_launcher
			@client_launcher = client_launcher
		end

		def is_ssh?
			! Strink.empty_s?(ENV["SSH_CONNECTION"])
		end

		def remote_setup_path(setup_lvl)
			case setup_lvl
			when Enums::SetupLvls::API
				@api_launcher.startup_api
			when Enums::SetupLvls::CLIENT
				@client_launcher.setup_client
			else
				raise "Setup path not configured"
			end
		end

	end
end