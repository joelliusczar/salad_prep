require "fileutils"
require_relative "../file_herder/file_herder"

module SaladPrep
	class ClientLauncher
		def initialize(egg)
			@egg = egg
		end

		def setup_client()
			FileHerder::empty_dir(File.join(@egg.web_root, @egg.client_dest))
			script = <<~CALL
					if [ -z "$NVM_DIR" ]; then
						export NVM_DIR="$HOME"/.nvm
						[ -s "$NVM_DIR"/nvm.sh ] && \. "$NVM_DIR"/nvm.sh  # This loads nvm
					fi &&
					export VITE_API_VERSION=v1 &&
					export VITE_BASE_ADDRESS="#{@egg.full_url}" &&
					#set up react then copy
					#install packages
					npm --prefix #{@egg.client_src} i &&
					#build code (transpile it)
					npm run --prefix '#{@egg.client_src}' build &&
			CALL
			FileUtils.cp_r(
				File.join(@egg.client_src, "build/"),
				File.join(@egg.web_root, @egg.client_dest)
			)
		end

	end
end