require "fileutils"
require "securerandom"
require_relative "../strink/strink"
require_relative "../file_herder/file_herder"
require_relative "../box_box/enums"

module SaladPrep
	class Egg

		attr_reader :project_name_0,
			:local_repo_path, :bin_dir, :test_flag,
			:env_prefix, :content_dir, :build_dir,
			:repo_url, :url_base

		def initialize (
			project_name_0:,
			local_repo_path:,
			repo_url:,
			env_prefix:,
			url_base:,
			tld:,
			bin_dir: ".local/bin",
			app_root: nil,
			web_root: nil,
			test_flag: false,
			content_dir: "content",
			api_port: 8033
		)
			if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ env_prefix)
				raise "env prefix is using an illegal form. "
					"Please use begin with letter and only use alphanumeric "
					"for rest with a max length of 6"
			end
			@project_name_0 = project_name_0
			@local_repo_path = local_repo_path
			@env_prefix = env_prefix
			@url_base = url_base
			@tld = tld
			@bin_dir = bin_dir
			@app_root = Strink::empty_s?(app_root) ? ENV["HOME"] : app_root
			@test_flag = test_flag
			@test_root = "#{repo_path}/test_trash"
			@build_dir = "builds"
			@content_dir = content_dir
			@api_port = api_port
		end

		def app_root
			if @test_flag
				return @test_root
			end
			return @app_root
		end

		def web_root
			if @test_flag
				return @test_root
			end
			case Gem::Platform::local.os
			when BoxOSes.LINUX
				unless Strink::empty_s?(@web_root)
					"/srv"
				else
					@web_root
				end
			when BoxOSes.MACOS
				unless Strink::empty_s?(@web_root)
					"/Library/WebServer"
				else
					@web_root
				end
			else
				raise "web root path not implemented"
			end
		end

		def project_name_snake
			Strink::to_snake(@project_name_0)
		end

		def app
			project_name_snake
		end

		def app_trunk
			app
		end

		def file_prefix
			@env_prefix.downcase
		end

		def repo_path
			if ! Strink::empty_s?(@local_repo_path)
				return @local_repo_path
			elsif is_current_dir_repo(Dir.pwd)
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
				port = Strink::empty_s?(port) ? "" : ":#{port}"
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

		def env_find (key, keyRegex, checkLocal=true)
			if ! Strink::empty_s?(ENV[key]) && !(is_local? && checkLocal)
				return ENV[key]
			end
			File.open(key_file, "r") do |file|
				file.each_line()
					.filter_map {|e| e[keyRegex, 1]}
					.first()
			end
		end

		def pb_secret
			env_find("PB_SECRET", /PB_SECRET=(\w+)/)
		end

		def pb_api_key
			env_find("PB_API_KEY", /PB_API_KEY=(\w+)/)
		end

		def api_auth_key
			env_find("#{@env_prefix}_AUTH_SECRET_KEY", /AUTH_SECRET_KEY=(\w+)/)
		end

		def namespace_uuid
			env_find("#{@env_prefix}_NAMESPACE_UUID", /NAMESPACE_UUID=([\w\-]+)/)
		end

		def db_setup_key
			env_find("#{@env_prefix}_DB_PASS_SETUP", /DB_PASS_SETUP=(\w+)/ )
		end

		def db_owner_key
			env_find("#{@env_prefix}_DB_PASS_OWNER", /DB_PASS_OWNER=(\w+)/)
		end
 
		def api_db_user_key
			env_find("#{@env_prefix}_DB_PASS_API", /DB_PASS_API=(\w+)/)
		end

		def janitor_db_user_key
			env_find("#{@env_prefix}_DB_PASS_JANITOR", /DB_PASS_JANITOR=(\w+)/)
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

		def run_test_block
			@test_flag = true
			yield
			@test_flag = false
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

		def lib_src
			"#{repo_path}/src/#{lib}"
		end

		def templates_src
			"#{repo_path}/templates"
		end

		def template_dest_suffix
			"#{app_trunk}/templates"
		end

		def sql_scripts_src
			"#{repo_path}/sql_scripts"
		end

		def sql_scripts_dest_suffix
			"#{app_trunk}/sql_scripts"
		end

		def config_dir
			"#{app_trunk}/config"
		end

		def api_src
			"#{repo_path}/src/api"
		end

		def api_dest_suffix
			"api/#{app}"
		end

		def client_src
			"#{repo_path}/src/client"
		end

		def client_dest
			"client/#{app}"
		end

		def server_env_check_recommended
			if Strink::empty_s?(ENV["#{@env_prefix}_DB_PASS_SETUP"])
				puts("environmental var #{@env_prefix}_DB_PASS_SETUP} not set in keys")
			end
			if Strink::empty_s?(ENV["#{@env_prefix}_DB_PASS_SETUP"])
				puts("environmental var #{@env_prefix}_DB_PASS_SETUP} not set in keys")
			end
		end

		def server_env_check_required
			result = true
			if Strink::empty_s?(repo_path)
				result = false

			end
		end

		def server_env_check
			puts("checking environment vars on server")
			server_env_check_recommended
			server_env_check_required
		end
 
	end
end