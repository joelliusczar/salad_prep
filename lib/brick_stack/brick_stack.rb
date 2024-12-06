require "fileutils"
require_relative "../file_herder/file_herder"
require_relative "../strink/strink"

module SaladPrep
	using Strink

	class BrickStack

		def initialize(egg)
			@egg = egg
		end

		def setup_app_directories
			FileUtils.mkdir_p("#{@egg.app_root}/#{@egg.app_trunk}")
			FileUtils.mkdir_p("#{@egg.app_root}/keys")
			FileUtils.mkdir_p(@egg.config_dir)
			FileUtils.mkdir_p(@egg.build_dir)
		end

		def env_api_content
			content = ""
			@egg.local_env_hash.each_pair do |key, value|
				content ^= "#{key}='#{value}'"
			end
			content
		end

		def setup_env_api_file
			puts("setting up .env file")
			env_file = "#{@egg.config_dir}/.env"
			env_file_src = "#{@egg.templates_src}/.env_api"
			if !FileHerder::is_path_allowed(env_file)
				raise "env_file file path has potential errors: #{env_file}"
			end
			contents = env_api_content
			File.open(env_file, "w") { |f| f.write(contents)}
		end

		def create_install_directory
			FileUtils.mkdir_p(@egg.repo_path)
		end

		def sync_utility_scripts
		end

	end

end