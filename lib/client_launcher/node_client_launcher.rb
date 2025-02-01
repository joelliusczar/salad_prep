require "fileutils"
require_relative "./client_launcher"
require_relative "../box_box/box_box"
require_relative "../extensions/string_ex"
require_relative "../file_herder/file_herder"


module SaladPrep
	class NodeClientLauncher < ClientLauncher
		using StringEx

		def initialize(egg, node_version:)
			super(egg)
			@node_version = node_version
		end

		def setup_client
			@egg.client_dest.path_check
			@egg.full_url.path_check
			@egg.api_version.api_version_check
			@node_version.pkg_version_check
			BoxBox.run_root_block do
				FileHerder.empty_dir(@egg.client_dest)
			end
			script = <<~CALL
					asdf local nodejs #{@node_version} &&
					export VITE_API_VERSION='#{@egg.api_version}' &&
					export VITE_BASE_ADDRESS='#{@egg.full_url}' &&
					#set up react then copy
					#install packages
					npm --prefix '#{@egg.client_src}' i &&
					#build code (transpile it)
					npm run --prefix '#{@egg.client_src}' build
			CALL
			BoxBox.script_run(script, exception: true)
			BoxBox.run_root_block do
				FileUtils.cp_r(
					File.join(@egg.client_src, "build/."),
					@egg.client_dest
				)
				FileHerder.unroot(@egg.client_dest)
			end
		end

	end
end