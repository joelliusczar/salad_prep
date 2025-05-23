require_relative "./api_launcher"

module SaladPrep
	class StaticAPILauncher < APILauncher

		def initialize(client_launcher:, **rest)
			super(**rest)
			@client_launcher = client_launcher
		end

		def copy_api_files
		end

		def setup_api
			@client_launcher.setup_client
			super
		end

	end
end