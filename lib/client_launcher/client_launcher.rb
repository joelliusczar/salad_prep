require "fileutils"
require_relative "../file_herder/file_herder"

module SaladPrep
	class ClientLauncher
		def initialize(egg)
			@egg = egg
		end

		def setup_client()
			FileHerder::empty_dir(@egg.client_dest)
			FileUtils.cp_r(
				File.join(@egg.client_src, "build/"),
				@egg.client_dest
			)
		end

	end
end