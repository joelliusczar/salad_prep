require "fileutils"
require_relative "../file_herder/file_herder.rb"

module SaladPrep
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
			FileUtils.mkdir_p("#{@egg.app_root}/#{@egg.config_dir}")
			FileUtils.mkdir_p("#{@egg.app_root}/#{@egg.build_dir}")
		end

		def env_api_content
			env_file_src = "#{@egg.templates_src}/.env_api"
			if !FileHerder::is_path_allowed(env_file_src)
				raise "env_file_src file path has potential errors: #{env_file_src}"
			end
			content = File.read(env_file_src)
			content.gsub!(
				%r{^(#{@egg.env_prefix}_CONTENT_DIR=).*\$},
				"\1'#{@egg.content_dir}'"
			)
			content.gsub!(
				%r{^(#{@egg.env_prefix}_TEMPLATES_DIR=).*\$},
				"\1'#{@egg.template_dest(abs: false)}'"
			)
			content.gsub!(
				%r{^(#{@egg.env_prefix}_SQL_SCRIPTS_DIR=).*\$},
				"\1'#{@egg.sql_scripts_dest(abs:false)}'"
			)
			env_value = ENV["#{@env_prefix}_DB_PASS_SETUP"]
			content.gsub!(
				%r{^(#{@egg.env_prefix}_DB_PASS_SETUP=).*\$},
				"\1'#{env_value}'"
			)

			env_value = ENV["#{@env_prefix}_DB_PASS_OWNER"]
			content.gsub!(
				%r{^(#{@egg.env_prefix}_DB_PASS_OWNER=).*\$},
				"\1'#{env_value}'"
			)

			env_value = ENV["#{@env_prefix}_DB_PASS_API"]
			content.gsub!(
				%r{^(#{@egg.env_prefix}_DB_PASS_API=).*\$},
				"\1'#{env_value}'"
			)

			env_value = ENV["#{@env_prefix}_DB_PASS_JANITOR"]
			content.gsub!(
				%r{^(#{@egg.env_prefix}_DB_PASS_JANITOR=).*\$},
				"\1'#{env_value}'"
			)
			
			env_value = ENV["#{@env_prefix}_TEST_ROOT"]
			content.gsub!(
				%r{^(#{@egg.env_prefix}_TEST_ROOT=).*\$},
				"\1'#{env_value}'"
			)

			env_value = ENV["#{@env_prefix}_NAMESPACE_UUID"]
			content.gsub!(
				%r{^(#{@egg.env_prefix}_NAMESPACE_UUID=).*\$},
				"\1'#{env_value}'"
			)
			
			env_value = ENV["#{@env_prefix}_API_LOG_LEVEL"]
			content.gsub!(
				%r{^(#{@egg.env_prefix}_API_LOG_LEVEL=).*\$},
				"\1'#{env_value}'"
			)
		end

		def setup_env_api_file
			puts("setting up .env file")
			env_file = "#{@egg.app_root}/#{egg.config_dir}/.env"
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