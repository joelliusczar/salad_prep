require "fileutils"
require_relative "../file_herder/file_herder"

module SaladPrep
	class ClientLauncher
		def initialize(egg)
			@egg = egg
		end

		def setup_client()
			FileHerder.empty_dir(@egg.client_dest)
			BoxBox.run_root_block do
				FileUtils.cp_r(
					File.join(@egg.client_src, "."),
					@egg.client_dest
				)
				FileHerder.unroot(@egg.client_dest)
			end
		end

	end
end