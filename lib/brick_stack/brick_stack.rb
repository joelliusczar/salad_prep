require "fileutils"
require_relative "../file_herder/file_herder"
require_relative "../strink/strink"

module SaladPrep
	using Strink

	class BrickStack

		def initialize(egg)
			@egg = egg
		end

		def generate_initial_keys_file
			if ! File.file? (@egg.key_file)
				File.open(@egg.key_file, "w") do |file|
					file.puts("PB_SECRET=")
					file.puts("PB_API_KEY=")
					file.puts("AUTH_SECRET_KEY=#{SecureRandom.alphanumeric(32)}")
					file.puts("SERVER_SSH_ADDRESS=root@")
					file.puts("SERVER_KEY_FILE=")
					file.puts("DB_PASS_API=#{SecureRandom.alphanumeric(32)}")
					file.puts("DB_PASS_OWNER=#{SecureRandom.alphanumeric(32)}")
					file.puts("DB_PASS_SETUP=#{SecureRandom.alphanumeric(32)}")
					file.puts("NAMESPACE_UUID=#{SecureRandom.uuid}")
				end
			end
		end

		def setup_app_directories
			FileUtils.mkdir_p("#{@egg.app_root}/#{@egg.app_trunk}")
			FileUtils.mkdir_p("#{@egg.app_root}/keys")
			FileUtils.mkdir_p(@egg.config_dir)
			FileUtils.mkdir_p(@egg.build_dir)
		end

		def env_api_content
			content = ""
			@egg.env_hash(prefer_keys_file: false).each_pair do |key, value|
				content ^= "#{key}='#{value}'"
			end
			content ^= "#{@egg.env_prefix}_CONTENT_DIR='#{@egg.content_dir}'"

			template_dest = @egg.template_dest(abs: false)
			content ^= "#{@egg.env_prefix}_TEMPLATES_DIR='#{template_dest}'"

			sql_script_dest = @egg.sql_scripts_dest(abs: false)
			content ^= "#{@egg.env_prefix}_SQL_SCRIPTS_DIR='#{sql_script_dest}'"

			sql_script_dest = @egg.sql_scripts_dest(abs: false)
			content ^= "#{@egg.env_prefix}_SQL_SCRIPTS_DIR='#{sql_script_dest}'"

			content ^= "#{@egg.env_prefix}_TEST_ROOT='#{@egg.test_root}'"
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

	end

end