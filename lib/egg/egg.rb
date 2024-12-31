require "fileutils"
require "securerandom"
require_relative "../box_box/enums"
require_relative "../file_herder/file_herder"
require_relative "../method_marker/method_marker"
require_relative "../extensions/object_ex"
require_relative "../extensions/string_ex"
require_relative "../loggable/loggable"

module SaladPrep
	
	class Egg
		using StringEx
		using ObjectEx
		extend MethodMarker
		include Loggable

		def initialize(**kwargs)
			marked_methods(:init_rq).each do |symbol|
				attrs = method_attrs(symbol)
				arg = kwargs[symbol]
				if arg.nil? && ! attrs.include?(:default)
					raise(
						ArgumentError,
						"#{symbol} requires value but none was provided"
					)
				end
				instance_variable_set(symbol.instancify, arg || attrs[:default])
			end
			@test_flags = 0
			@build_dir = "builds"
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

		def env_find (key, keyRegex = nil, prefer_keys_file: true)
			if is_local?
				if prefer_keys_file && keyRegex.embodied?
					return File.open(key_file, "r") do |file|
						file.each_line()
							.filter_map {|e| e[keyRegex, 1]}
							.first()
					end
				end
			end
			return ENV[key]
		end

		def self.def_env_find(symbol, key, keyRegex = nil, mark = :prefixed_env_key)
			mark_for(**{mark => key})
			define_method(symbol) do |prefer_keys_file: true|
				env_find(
					mark == :prefixed_env_key ? "#{env_prefix}_#{key}" : key,
					keyRegex,
					prefer_keys_file:
				)
			end
		end

		def env_exports
			exports = ""
			env_hash.each_pair do |key, value|
				exports += "export #{key}='#{value}'; "
			end
			exports
		end

		def app_lvl_definitions_script
			"raise 'app_lvl_definitions_script not implemented'"
		end

		def is_current_dir_repo? (dir)
			return false unless File.file?("#{dir}/README.md")
			return false unless File.exist?("#{dir}/src")
			return false unless File.exist?("#{dir}/test_trash")
		end

		mark_for(:init_rq)
		def env_prefix
			@env_prefix
		end

		mark_for
		def test_flags
			@test_flags
		end

		mark_for(fixed_dir: true, prefixed_env_key: "TEST_ROOT")
		def test_root
			"#{repo_path}/test_trash"
		end

		mark_for(:init_rq, default: ENV["HOME"])
		def app_root
			if @test_flags > 0
				return test_root
			end
			return @app_root
		end

		mark_for(:init_rq, default: nil)
		def web_root
			if @test_flags > 0
				return test_root
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

		mark_for(:init_rq)
		def project_name_0
			@project_name_0
		end

		mark_for
		def project_name_snake
			project_name_0.to_snake
		end

		mark_for
		def app
			project_name_snake
		end

		mark_for
		def app_trunk
			app
		end

		mark_for
		def file_prefix
			@env_prefix.downcase + "_env"
		end

		mark_for(
			:init_rq,
			:server_rq,
			:deploy_rq,
			:env_enum,
			prefixed_env_key: "REPO_URL"
		)
		def repo_url
			@repo_url
		end

		def repo_path
			if ! local_repo_path.zero?
				return local_repo_path
			elsif is_current_dir_repo?(Dir.pwd)
				return Dir.pwd
			else
				return "#{ENV['HOME']}/#{@build_dir}/#{project_name_snake}"
			end
		end

		mark_for(
			:init_rq,
			:server_rq,
			:deploy_sg,
			:env_enum,
			prefixed_env_key: "LOCAL_REPO_DIR",
			default: nil
		)
		def local_repo_path
			@local_repo_path
		end

		mark_for(:init_rq, default: 8032)
		def api_port
			@api_port
		end

		mark_for(:init_rq, default: 8033)
		def test_port
			@test_port
		end

		mark_for(:init_rq)
		def tld
			@tld
		end

		mark_for(:init_rq)
		def url_base
			@url_base
		end

		mark_for(:server_rq, :deploy_rq)
		def domain_name(port: nil)
			if is_local?
				port = port.zero? ? "" : ":#{port}"
				"#{url_base}-local.#{tld}#{port}"
			else
				"#{url_base}.#{tld}"
			end
		end

		mark_for
		def full_url
			"https://#{domain_name}"
		end

		mark_for(
			:init_rq,
			:env_enum,
			default: "v1",
			prefixed_env_key: "API_VERSION"
		)
		def api_version
			@api_version
		end

		def is_local?
			ENV["#{@env_prefix}_ENV"] == "local"
		end

		mark_for
		def key_file
			"#{app_root}/keys/#{project_name_snake}"
		end

		mark_for(:server_rq, :deploy_rq, :env_enum)
		def_env_find(:pb_secret, "PB_SECRET", nil, :env_key)

		mark_for(:server_rq, :deploy_rq, :env_enum)
		def_env_find(:pb_api_key, "PB_API_KEY", nil, :env_key)

		mark_for(
			:server_rq,
			:deploy_rq,
			:env_enum,
			gen_key: SecureRandom.alphanumeric(32)
		)
		def_env_find(:api_auth_key, "AUTH_SECRET_KEY", /AUTH_SECRET_KEY=(\w+)/)

		mark_for(
			:server_rq,
			:deploy_rq,
			:env_enum,
			gen_key: SecureRandom.uuid
		)
		def_env_find(:namespace_uuid, "NAMESPACE_UUID", /NAMESPACE_UUID=([\w\-]+)/)

		mark_for(
			:deploy_sg,
			:env_enum,
			gen_key: SecureRandom.alphanumeric(32)
		)
		def_env_find(:db_setup_key, "DB_PASS_SETUP", /DB_PASS_SETUP=(\w+)/)

		mark_for(:init_rq)
		def db_owner_name
			@db_owner_name
		end

		mark_for(
			:deploy_sg,
			:env_enum,
			gen_key: SecureRandom.alphanumeric(32)
		)
		def_env_find(:db_owner_key, "DB_PASS_OWNER", /DB_PASS_OWNER=(\w+)/)

		mark_for(
			:server_rq,
			:deploy_rq,
			:env_enum,
			gen_key: SecureRandom.alphanumeric(32)
		)
		def_env_find(:api_db_user_key, "DB_PASS_API", /DB_PASS_API=(\w+)/)
 
		mark_for(:server_rq, :deploy_rq, :env_enum)
		def_env_find(
			:janitor_db_user_key,
			"DB_PASS_JANITOR",
			/DB_PASS_JANITOR=(\w+)/
		)

		mark_for(:deploy_sg, :env_enum)
		def_env_find(:api_log_level, "API_LOG_LEVEL")

		def log_dest(name="")
			value = ENV["#{@env_prefix}#{name}_LOG_DEST"]
			if value.zero?
				nil
			elsif value.downcase == "stdout" 
				$stdout
			elsif value.downcase == "stderr"
					$stderr 
			else
				File.open(value, "a")
			end
		end

		def set_logs
			self.log = log_dest
			self.warning_log = log_dest("_WARN")
			self.diag_log = log_dest("_DIAG")
			self.huge_log = log_dest("_HUGE")
			self.error_log = $stderr
		end

		mark_for(:deploy_sg, :env_enum)
		def_env_find(:build_log_dest, "LOG_DEST")
		mark_for(:deploy_sg, :env_enum)
		def_env_find(:build_warning_log_dest, "WARN_LOG_DEST")
		mark_for(:deploy_sg, :env_enum)
		def_env_find(:build_diag_log_dest, "DIAG_LOG_DEST")
		mark_for(:deploy_sg, :env_enum)
		def_env_find(:build_huge_log_dest, "HUGE_LOG_DEST")

		mark_for(:env_enum, prefixed_env_key: "DATABASE_NAME")
		def db_name
			"#{project_name_snake}_db"
		end

		mark_for(:deploy_rq)
		def ssh_address
			ENV["#{@env_prefix}_SERVER_SSH_ADDRESS"]
		end

		mark_for(:deploy_rq)
		def ssh_id_file
			ENV["#{@env_prefix}_SERVER_KEY_FILE"]
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

		mark_for
		def lib_import
			project_name_snake
		end

		mark_for
		def src
			"#{repo_path}/src"
		end

		mark_for
		def lib_src
			"#{src}/#{lib}"
		end

		mark_for
		def templates_src
			"#{repo_path}/templates"
		end

		mark_for(fixed_dir: false, prefixed_env_key: "TEMPLATES_DEST")
		def template_dest(abs:true)
			suffix = File.join(app_trunk, "templates")
			abs_suffix(suffix, abs)
		end

		mark_for
		def sql_scripts_src
			"#{repo_path}/sql_scripts"
		end

		mark_for(fixed_dir: false, prefixed_env_key: "SQL_SCRIPTS_DEST")
		def sql_scripts_dest(abs: true)
			suffix = File.join(app_trunk, "sql_scripts")
			abs_suffix(suffix, abs)
		end

		mark_for(
			:init_rq,
			fixed_dir: true,
			default: "content",
			prefixed_env_key: "CONTENT_DIR"
		)
		def content_dir(abs: true)
			suffix = File.join(app_trunk, @content_dir)
			abs_suffix(suffix, abs)
		end

		mark_for
		def config_dir(abs: true)
			suffix = File.join(app_trunk, "config")
			abs_suffix(suffix, abs)
		end

		mark_for
		def api_src
			"#{repo_path}/src/api"
		end

		mark_for
		def api_dest(abs: true)
			suffix = File.join("api", app)
			abs_suffix_web(suffix, abs)
		end

		mark_for
		def client_src
			"#{repo_path}/src/client"
		end

		mark_for
		def client_dest(abs: true)
			suffix = File.join("client", app)
			abs_suffix_web(suffix, abs)
		end

		mark_for
		def build_dir(abs: true)
			abs_suffix(@build_dir, abs)
		end

		mark_for(:init_rq, default: ".local")
		def bin_parent_dir(abs: true)
			abs_suffix(@bin_parent_dir, abs)
		end

		mark_for
		def dev_ops_bin
			abs_suffix(".#{env_prefix}_bin", abs: true)
		end

		mark_for
		def bin_dir(abs: true)
			File.join(bin_parent_dir(abs: abs), "bin")
		end

		def generate_initial_keys_file
			if ! File.file? (key_file)
				File.open(key_file, "w") do |file|
					marked_methods(:gen_key).each do |symbol|
						attrs = method_attrs(symbol)
						key = attrs[:prefixed_env_key]
						value = attrs[:gen_key]
						file.puts("#{key}=#{value}")
					end
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

		def env_hash(prefer_keys_file: true, include_dirs: false)
			marked_methods(:env_key, :env_enum).to_h do |symbol|
				attrs = method_attrs(symbol)
				key = attrs[:env_key]
				[key, send(symbol, prefer_keys_file:)]
			end.merge(
				marked_methods(:prefixed_env_key, :env_enum).to_h do |symbol|
					attrs = method_attrs(symbol)
					key = attrs[:prefixed_env_key]
					hash_key = "#{env_prefix}_#{key}"
					m = method(symbol)
					if m.parameters.none?
						[hash_key, send(symbol)]
					elsif m.parameters.any? {|p| p[1] == :prefer_keys_file} 
						[hash_key, send(symbol, prefer_keys_file:)]
					else
						[hash_key, ""]
					end
				end
			).merge(
				include_dirs ? marked_methods(
					:prefixed_env_key,
					:fixed_dir
				).to_h do |symbol|
					attrs = method_attrs(symbol)
					key = attrs[:prefixed_env_key]
					if attrs[:fixed_dir]
						["#{env_prefix}_#{key}", send(symbol)]
					else
						["#{env_prefix}_#{key}", send(symbol, abs: false)]
					end
				end : {}
			).reject {|k, v| v.zero? }
		end

		def load_env
			env_hash(include_dirs: true).each_pair do |key, value|
				ENV[key] = value
			end
			ENV["#{env_prefix}_APP_ROOT"] = @app_root
			ENV["__TEST_FLAG__"] = @test_flags > 0 ? "true" : ""
			set_logs
		end

		def server_env_check_recommended
			marked_methods(:deploy_sg).filter do |symbol|
				send(symbol).zero?
			end
		end

		def server_env_check_required
			marked_methods(:server_rq).filter do |symbol|
				m = method(symbol)
				if m.parameters.none?
					m.call.zero?
				elsif m.parameters.any? { |p| p[1] == :prefer_keys_file}
					m.call(prefer_keys_file: false).zero?
				end
			end
		end

		def deployment_env_check_recommended
			marked_methods(:deploy_sg).filter do |symbol|
				send(symbol).zero?
			end
		end

		def deployment_env_check_required
			raise "key file not setup #{key_file}" if ! File.size?(key_file)
			marked_methods(:deploy_rq).filter do |symbol|
				send(symbol).zero?
			end
		end
 
		def dev_env_check_recommended
			marked_methods(:dev_sg).filter do |symbol|
				send(symbol).zero?
			end
		end

		def dev_env_check_required
			marked_methods(:server_rq).filter do |symbol|
				m = method(symbol)
				if m.parameters.length < 1
					m.call.zero?
				elsif m.parameters.any? { |p| p[1] == :prefer_keys_file}
					m.call(prefer_keys_file: false).zero?
				end
			end
		end

		def to_s
			super + "\n" + marked_methods.sort.map do |symbol|
				"#{symbol} => \"#{send(symbol)}\""
			end * "\n"
		end

	end
end