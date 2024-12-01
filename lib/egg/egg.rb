require "fileutils"
require "securerandom"
require_relative "../strink/strink"
require_relative "../file_herder/file_herder"
require_relative "../box_box/enums"

module SaladPrep
	using Strink

	class Egg

		attr_reader :project_name_0,
			:local_repo_path, :test_flags,
			:env_prefix, :content_dir,
			:repo_url, :url_base, :test_root, :api_port

		def initialize (
			project_name_0:,
			repo_url:,
			env_prefix:,
			url_base:,
			tld:,
			local_repo_path: nil,
			bin_dir: ".local/bin",
			app_root: nil,
			web_root: nil,
			content_dir: "content",
			api_port: 8033
		)
			if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ env_prefix)
				raise "env prefix is using an illegal form. "
					"Please use begin with letter and only use alphanumeric "
					"for rest with a max length of 6"
			end
			@project_name_0 = project_name_0
			@repo_url = repo_url
			@local_repo_path = local_repo_path
			@env_prefix = env_prefix
			@url_base = url_base
			@tld = tld
			@bin_dir = bin_dir
			@app_root = app_root.zero? ? ENV["HOME"] : app_root
			@web_root = web_root
			@test_flags = 0
			@test_root = "#{repo_path}/test_trash"
			@build_dir = "builds"
			@content_dir = content_dir
			@api_port = api_port
		end

		def app_root
			if @test_flags > 0
				return @test_root
			end
			return @app_root
		end

		def web_root
			if @test_flags > 0
				return @test_root
			end
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if @web_root.zero?
					"/srv"
				else
					@web_root
				end
			when Enums::BoxOSes::MACOS
				if @web_root.zero?
					"/Library/WebServer"
				else
					@web_root
				end
			else
				raise "web root path not implemented"
			end
		end

		def project_name_snake
			@project_name_0.to_snake
		end

		def app
			project_name_snake
		end

		def app_trunk
			app
		end

		def file_prefix
			@env_prefix.downcase + "_env"
		end

		def repo_path
			if ! @local_repo_path.zero?
				return @local_repo_path
			elsif is_current_dir_repo?(Dir.pwd)
				return Dir.pwd
			else
				return "#{ENV['HOME']}/#{@build_dir}/#{project_name_snake}"
			end

		end

		def is_current_dir_repo? (dir)
			return false unless File.file?("#{dir}/README.md")
			return false unless File.exist?("#{dir}/src")
			return false unless File.exist?("#{dir}/test_trash")
		end

		def domain_name(port: nil)
			if is_local?
				port = port.zero? ? "" : ":#{port}"
				"#{@url_base}-local.#{@tld}#{port}"
			else
				"#{@url_base}.#{@tld}"
			end
		end

		def full_url
			"https://#{domain_name}"
		end

		def is_local?
			ENV["#{@env_prefix}_ENV"] == "local"
		end

		def key_file
			"#{app_root}/keys/#{project_name_snake}"
		end

		def env_find (key, keyRegex, prefer_keys_file=true)
			if ENV[key].populated? && !(is_local? && prefer_keys_file)
				return ENV[key]
			end
			File.open(key_file, "r") do |file|
				file.each_line()
					.filter_map {|e| e[keyRegex, 1]}
					.first()
			end
		end

		def pb_secret(prefer_keys_file: true)
			env_find(
				"PB_SECRET",
				/PB_SECRET=(\w+)/,
				prefer_keys_file
			)
		end

		def pb_api_key(prefer_keys_file: true)
			env_find(
				"PB_API_KEY",
				/PB_API_KEY=(\w+)/,
				prefer_keys_file
			)
		end

		def api_auth_key(prefer_keys_file: true)
			env_find(
				"#{@env_prefix}_AUTH_SECRET_KEY",
				/AUTH_SECRET_KEY=(\w+)/,
				prefer_keys_file
			)
		end

		def namespace_uuid
			env_find(
				"#{@env_prefix}_NAMESPACE_UUID",
				/NAMESPACE_UUID=([\w\-]+)/
			)
		end

		def db_setup_key(prefer_keys_file: true)
			env_find(
				"#{@env_prefix}_DB_PASS_SETUP",
				/DB_PASS_SETUP=(\w+)/,
				prefer_keys_file
			)
		end

		def db_owner_key(prefer_keys_file: true)
			env_find(
				"#{@env_prefix}_DB_PASS_OWNER",
				/DB_PASS_OWNER=(\w+)/,
				prefer_keys_file
			)
		end
 
		def api_db_user_key(prefer_keys_file: true)
			env_find(
				"#{@env_prefix}_DB_PASS_API",
				/DB_PASS_API=(\w+)/,
				prefer_keys_file
			)
		end

		def janitor_db_user_key(prefer_keys_file: true)
			env_find(
				"#{@env_prefix}_DB_PASS_JANITOR",
				/DB_PASS_JANITOR=(\w+)/,
				prefer_keys_file
			)
		end

		def api_log_level
			ENV["#{env_prefix}_API_LOG_LEVEL"]
		end

		def ssh_address
			env_find(
				"#{@env_prefix}_SERVER_SSH_ADDRESS",
				/SERVER_SSH_ADDRESS=root@([\w:]+)/,
				checkLocal=false
			)
		end

		def ssh_id_file
			env_find(
				"#{@env_prefix}_SERVER_KEY_FILE",
				/SERVER_KEY_FILE=(.+)/,
				checkLocal=false
			)
		end


		def generate_initial_keys_file
			if ! File.file? (key_file)
				File.open(key_file, "w") do |file|
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

		def run_test_block
			@test_flags +=1
			generate_initial_keys_file
			load_env
			yield
			@test_flags -= 1
			load_env if @test_flags == 0
		end

		def get_localhost_ssh_dir
			"#{ENV["HOME"]}/.ssh"
		end
	
		def get_debug_cert_name
			"#{project_name_snake}_localhost_debug"
		end
	
		def get_debug_cert_path
			"#{get_localhost_ssh_dir}/#{get_debug_cert_name}"
		end

		def lib
			"engine"
		end

		def lib_import
			project_name_snake
		end

		def src
			"#{repo_path}/src"
		end

		def lib_src
			"#{src}/#{lib}"
		end

		def templates_src
			"#{repo_path}/templates"
		end

		def abs_suffix(suffix, abs=true)
			if abs
				return File.join(app_root, suffix)
			end
			return suffix
		end

		def abs_suffix_web(suffix, abs=true)
			if abs
				return File.join(web_root, suffix)
			end
			return suffix
		end

		def template_dest(abs:true)
			suffix = File.join(app_trunk, "templates")
			abs_suffix(suffix, abs)
		end

		def sql_scripts_src
			"#{repo_path}/sql_scripts"
		end

		def sql_scripts_dest(abs: true)
			suffix = File.join(app_trunk, "sql_scripts")
			abs_suffix(suffix, abs)
		end

		def config_dir(abs: true)
			suffix = File.join(app_trunk, "config")
			abs_suffix(suffix, abs)
		end

		def api_src
			"#{repo_path}/src/api"
		end

		def api_dest(abs: true)
			suffix = File.join("api", app)
			abs_suffix_web(suffix, abs)
		end

		def client_src
			"#{repo_path}/src/client"
		end

		def client_dest(abs: true)
			suffix = File.join("client", app)
			abs_suffix_web(suffix, abs)
		end

		def build_dir(abs: true)
			abs_suffix(@build_dir, abs)
		end

		def bin_dir(abs: true)
			abs_suffix(@bin_dir, abs)
		end

		def env_hash(prefer_keys_file: true)
			{
				"PB_SECRET" =>
					pb_secret(prefer_keys_file: prefer_keys_file),

				"PB_API_KEY" =>
					pb_api_key(prefer_keys_file: prefer_keys_file),
				
				"#{env_prefix}_REPO_URL" =>
					repo_url,

				"#{env_prefix}_AUTH_SECRET_KEY" => 
					api_auth_key(prefer_keys_file: prefer_keys_file),

				"#{env_prefix}_NAMESPACE_UUID" => 
					namespace_uuid,

				"#{env_prefix}_DATABASE_NAME" => 
					"#{project_name_snake}_db",

				"#{env_prefix}_DB_PASS_SETUP" => 
					db_setup_key(prefer_keys_file: prefer_keys_file),

				"#{env_prefix}_DB_PASS_OWNER" => 
					db_owner_key(prefer_keys_file: prefer_keys_file),

				"#{env_prefix}_DB_PASS_API" => 
					api_db_user_key(prefer_keys_file: prefer_keys_file),

				"#{env_prefix}_DB_PASS_JANITOR" => 
					janitor_db_user_key(prefer_keys_file: prefer_keys_file),

				"#{env_prefix}_API_LOG_LEVEL" => 
					api_log_level
			}.reject {|k, v| v.zero? }
		end

		def local_env_hash
			{
				**env_hash(prefer_keys_file: false),

				"#{env_prefix}_CONTENT_DIR" =>
					content_dir,
				
				"#{env_prefix}_TEMPLATES_DEST" =>
					template_dest(abs: false),

				"#{env_prefix}_SQL_SCRIPTS_DEST" =>
					sql_scripts_dest(abs: false),

				"#{env_prefix}_TEST_ROOT" =>
					test_root
			}

		end

		def load_env
			local_env_hash.each_pair do |key, value|
				ENV[key] = value
			end
			ENV["#{env_prefix}_APP_ROOT"] = @app_root
			ENV["__TEST_FLAG__"] = @test_flags > 0 ? "true" : ""
		end

		def server_env_check_recommended
			result = []
			result.push("db_setup_key") if db_setup_key.zero?
			result.push("db_owner_key") if db_owner_key.zero?
			result
		end

		def server_env_check_required
			result = []
			result.push("repo_url") if repo_url.zero?
			result.push("local_repo_path") if repo_path.zero?
			result.push("domain_name") if domain_name.zero?

			result.push("pb_secret") if pb_secret(prefer_keys_file: false).zero?
			result.push("pb_api_key") if pb_api_key(prefer_keys_file: false).zero?

			result.push("api_auth_key") \
				if api_auth_key(prefer_keys_file: false).zero?
			result.push("namespace_uuid") if namespace_uuid.zero?

			result.push("api_db_user_key") \
				if api_db_user_key(prefer_keys_file: false).zero?
			result.push("janitor_db_user_key") \
				if janitor_db_user_key(prefer_keys_file: false).zero?
			result
		end

		def deployment_env_check_recommended
			result = []
			result.push("db_setup_key") if db_setup_key.zero?
			result.push("db_owner_key") if db_owner_key.zero?
			result.push("api_log_level") if api_log_level.zero?
			result
		end

		def deployment_env_check_required
			raise "key file not setup #{key_file}" if ! File.size?(key_file)
			result = []
			result.push("ssh_id_file") if ssh_id_file.zero?
			result.push("ssh_address") if ssh_address.zero?

			result.push("pb_secret") if pb_secret.zero?
			result.push("pb_api_key") if pb_api_key.zero?

			result.push("api_auth_key") if api_auth_key.zero?
			result.push("namespace_uuid") if namespace_uuid.zero?

			result.push("api_db_user_key") if api_db_user_key.zero?
			result.push("janitor_db_user_key") if janitor_db_user_key.zero?
			result
		end
 
		def dev_env_check_recommended
			result = []
			result.push("repo_url") if repo_url.zero?
			result.push("db_setup_key") if db_setup_key.zero?
			result.push("db_owner_key") if db_owner_key.zero?
			result
		end

		def dev_env_check_required
			result = []
			result.push("repo_url") if repo_url.zero?
			result.push("local_repo_path") if @local_repo_path.zero?
			result.push("domain_name") if domain_name.zero?

			result.push("pb_secret") if pb_secret(prefer_keys_file: false).zero?
			result.push("pb_api_key") if pb_api_key(prefer_keys_file: false).zero?

			result.push("api_auth_key") if api_auth_key(prefer_keys_file: false).zero?
			result.push("namespace_uuid") if namespace_uuid.zero?

			result.push("api_db_user_key") \
				if api_db_user_key(prefer_keys_file: false).zero?
			result.push("janitor_db_user_key") \
				if janitor_db_user_key(prefer_keys_file: false).zero?
			result
		end

	end
end