require "fileutils"
require_relative "./client_launcher"
require_relative "../file_herder/file_herder"
require_relative "../arg_checker/arg_checker"

module SaladPrep
	class NodeClientLauncher < ClientLauncher
		def initialize(egg, node_version:)
			super(egg)
			@node_version = node_version
		end

		def setup_client()
			ArgChecker.path(@egg.client_dest)
			ArgChecker.path(@egg.full_url)
			ArgChecker.api_version(@egg.api_version)
			ArgChecker.pkg_version(@node_version)
			FileHerder::empty_dir(@egg.client_dest)
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
			system(script, exception: true)
			FileUtils.cp_r(
				File.join(@egg.client_src, "build/"),
				@egg.client_dest
			)
		end

	end
end