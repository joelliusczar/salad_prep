require_relative "./api_launcher"

module SaladPrep
	class StaticAPILauncher < APILauncher

		def initialize(clientLauncher:, **rest)
			super(**rest)
			@clientLauncher = clientLauncher
		end

		def copy_api_files
		end

		def setup_api
			super
			@client_launcher.setup_client
		end

	end
end