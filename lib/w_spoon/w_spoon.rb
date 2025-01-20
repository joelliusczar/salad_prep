require "base64"
require "fileutils"
require 'json'
require 'net/http'
require "open3"
require "tempfile"
require_relative "../box_box/box_box"
require_relative "../box_box/enums"
require_relative "../egg/egg"
require_relative "../extensions/string_ex"
require_relative "../file_herder/file_herder"

module SaladPrep
	using StringEx

	class WSpoon

		def initialize(egg, resourcerer)
			@egg = egg
			@resourcerer = resourcerer
		end

		def get_nginx_value(key = "conf-path")
			BoxBox.process_path_append("/usr/sbin/")
			output = `nginx -V 2>&1` 
			output.split.find{|a| a =~ /--#{key}/}[/.*=(.*)/, 1]
		end

		def get_nginx_conf_dir_include(nginx_conf_path = get_nginx_value)
			guesses = [
				"include /etc/nginx/sites-enabled/*;",
				"include servers/*;"
			]
			guesses.first {|g| File.open(nginx_conf_path).read.include?(g) }
		end

		def get_abs_path_from_nginx_include(conf_dir_include)
			conf_dir = conf_dir_include
				.gsub(/include */, "")
				.gsub(/\*; */,"")
			if File.directory?(conf_dir)
				return conf_dir
			else
				nginx_conf_path = get_nginx_value
				sites_folder_path =  File.dirname(nginx_conf_path)
				abs_path = File.join(sites_folder_path, conf_dir)
				unless File.directory?(abs_path)
					if File.exist?(abs_path)
						raise "#{absPath} is a file, not a directory"
					end

					#Apparently nginx will look for includes with either an absolute path
					#or path relative to the config
					#some os'es are finicky about creating directories at the root lvl
					#even with sudo, so we're not going to even try
					#we'll just create missing dir in $sitesFolderPath folder
					BoxBox.run_root_block do
						FileHerder.mkdir(abs_path)
					end
				end
				return abs_path
			end
		end

		def add_test_url_to_hosts(domain)
			in_hosts = File.open("/etc/hosts") do |file| 
				file.any?{|l| l.include?(domain) }
			end
			unless in_hosts
				unless /[a-zA-Z0-9\-_\.]+-local\.[a-zA-Z0-9\.]/ =~ domain
					raise "#{domain} is not a valid local url"
				end
				BoxBox.run_root_block do
					system(
						"sudo",
						"sh",
						"-c",
						"printf '127.0.0.1\t#{domain}\n'",
						exception: true
					)
				end
			end
		end

		def localhost_ssh_dir
			File.join(ENV["HOME"],".ssh")
		end

		def local_nginx_cert_name
			"#{@egg.project_name_snake}_localhost_nginx"
		end

		def local_nginx_cert_path
			File.join(localhost_ssh_dir, local_nginx_cert_name)
		end

		def get_debug_cert_name
			"#{@egg.project_name_snake}_localhost_debug"
		end

		def debug_cert_path
			File.join(localhost_ssh_dir, get_debug_cert_name)
		end

		def keychain_osx
			"/Library/Keychains/System.keychain"
		end

		def remote_public_key()
			"/etc/ssl/certs/#{@egg.project_name_snake}.public.key.pem"
		end

		def remote_private_key()
			"/etc/ssl/private/#{@egg.project_name_snake}.private.key.pem"
		end

		def ssl_vars()
			data = 	<<~DATA
				{ 
					"secretapikey": "#{@egg.pb_secret}",
					"apikey": "#{@egg.pb_api_key}"
				}
			DATA

			path = "/api/json/v3/ssl/retrieve/#{@egg.domain_name}"
			res = Net::HTTP.start("api.porkbun.com", :use_ssl => true) do |http|
				http.post2(path, data)
			end

			JSON.parse(res.body)
		end

		def extract_sha256_from_cert(cert)
			IO.popen(
				["openssl", "x509", "-fingerprint", "-sha256"],
				"r+"
			) do |p|
				p.write(cert)
				p.close_write
				output = p.read
				output[/(?:SHA|sha)256 Fingerprint=([A-Za-z0-9:]+)/,1].tr(":","")
			end
		end

		def scan_pems_file_for_common_name(common_name, certs_file)
			cert = "".b
			lines = File.open(certs_file, "rb").readlines
			Enumerator.new do |yielder|
				lines.map(&:chomp).each do |line|
					next if line == "-----BEGIN CERTIFICATE-----".b
					if line == "-----END CERTIFICATE-----".b
						decoded = Base64.decode64(cert)
						output = IO.popen(["openssl", "x509", "-subject"], "r+") do |p|
							cert = "-----BEGIN CERTIFICATE-----\n".b \
							+ cert \
							+ "-----END CERTIFICATE-----".b
							p.write(cert)
							p.close_write
							p.read
						end
						
						if /CN *= *#{common_name}/ =~ output
							yielder << cert
						end
						cert = "".b
						next
					end
					cert += (line + "\n".b)
				end
			end
		end

		def certs_matching_name(common_name)
			unless /[a-zA-Z0-9\.\-_]+/ =~ common_name
				raise "Common name has illegal characters"
			end
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				`security find-certificate -a -p -c #{common_name} #{keychain_osx}`
			when Enums::BoxOSes::LINUX
				scan_pems_file_for_common_name(
					common_name,
					"/etc/ssl/certs/ca-certificates.crt"
				)
			else
				raise "OS not configured"
			end
		end

		def extract_subject_from_cert(cert)
			IO.popen(["openssl", "x509", "-subject"], "r+") do |p|
				p.write(cert)
				p.close_write
				p.read
			end
		end

		def extract_common_name_from_cert(cert)
			output = extract_subject_from_cert(cert)
			output[%r{CN *= *([^/\n]+)},1]
		end

		def any_certs_matching_name_exact(common_name)
			certs_matching_name(common_name).any? do |cert|
				extract_common_name_from_cert(cert) == common_name
			end
		end

		def is_cert_expired(cert)
			_, status = Open3.capture2(
				"openssl x509 -checkend 3600 -noout",
				stdin_data: cert
			)
			status.exitstatus == 0 ? false : true
		end

		def clean_up_invalid_cert(common_name, cert_name = nil)
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				certs_matching_name(common_name).each do |cert|
					sha_256_value = extract_sha256_from_cert(cert)
					if is_cert_expired(cert)
						BoxBox.run_root_block do
							system(
								"sudo",
								"security", "delete-certificate",
								"-z", sha_256_value, "-t", keychain_osx,
								exception: true
							)
						end
					end
				end
			when Enums::BoxOSes::LINUX
				certs_matching_name(common_name).each do |cert|
					if is_cert_expired(cert)
						cert_dir="/usr/local/share/ca-certificates"
						if cert_name.zero?
							cert_name = common_name
						end
						cert_name.domain_name_check
						BoxBox.run_root_block do
							system(
								"sudo",
								"rm",
								"#{cert_dir}/#{cert_name}*.crt"
							)
							system(
								"sudo",
								"update-ca-certificates",
								exception: true
							)
						end
					end
				end
			else
				raise "OS not implemented"
			end
		end

		def create_firefox_cert_policy_file(
			public_key_file_path,
			policy_file
		)
			if /[#"'\\*]/ =~ public_key_file_path
				raise "#{public_key_file_path} contains illegal characters"
			end
			if /[#"'\\*]/ =~ policy_file
				raise "#{policy_file} contains illegal characters"
			end
			pem_file = public_key_file_path.gsub(/.crt$/, ".pem")
			content = <<~POLICY
			{
				"policies": {
					"Certificates": {
						"ImportEnterpriseRoots": true,
						"Install": [
							"#{public_key_file_path}",
							"/etc/ssl/certs/#{pemFile}"
						]
					}
				}
			}
			POLICY
			BoxBox.run_root_block do
				System(
					"sudo",
					"sh",
					"-c",
					"echo '#{content}' > #{policy_file}",
					exception: true
				)
			end
		end

		def get_trusted_by_firefox_json_with_added_cert(
			public_key_file_path,
			policy_content
		)
			config = JSON.parse(policy_content)
			installed = config["policies"]["Certificates"]["Install"]
			unless installed.include?(public_key_file_path)
				installed.push(public_key_file_path)
			end
			pem_file = public_key_file_path.gsub(/.crt$/, ".pem")
			unless installed.include?("/etc/ssl/certs/#{pem_file}")
				installed.push("/etc/ssl/certs/#{pem_file}")
			end
			config.to_json
		end

		def set_firefox_cert_policy(public_key_file_path)
			if /[#"'\\*]/ =~ public_key_file_path
				raise "#{public_key_file_path} contains illegal characters"
			end
			policy_file="/usr/share/firefox-esr/distribution/policies.json"
			if system("firefox", "-v", err: File::NULL)
				if File.size?(policy_file)
					BoxBox.run_root_block do
						content = get_trusted_by_firefox_json_with_added_cert(
							public_key_file_path,
							File.open(policy_file).read
						)
						System(
							"sudo",
							"sh",
							"-c",
							"echo '#{content}' > #{policy_file}",
							exception: true
						)
					end
				else
					create_firefox_cert_policy_file(
						public_key_file_path,
						policy_file
					)
				end
			end
		end

		def openssl_default_conf
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				"/System/Library/OpenSSL/openssl.cnf"
			when Enums::BoxOSes::LINUX
				"/etc/ssl/openssl.cnf"
			else
			end
		end

		def openssl_gen_cert(
			common_name,
			domain,
			public_key_file_path,
			private_key_file_path
		)
			Tempfile.create do |file|
				file.write(File.open(openssl_default_conf).read)
				file.write("[SAN]\nsubjectAltName=DNS:#{domain},IP:127.0.0.1")
				file.rewind
				system(
					"openssl", "req","-x509", "-sha256", "-new", "-nodes", "-newkey",
					"rsa:2048", "-days", 7,
					"-subj", "/C=US/ST=CA/O=fake/CN=#{common_name}",
					"-reqexts", "SAN", "-extensions", "SAN",
					"-config", file.path, 
					"-keyout", private_key_file_path, "-out", private_key_file_path,
					exception: true
				)
			end
		end

		def install_local_cert_osx(public_key_file_path)
			BoxBox.run_root_block do
				system(
					"sudo",
					"security", "add-trusted-cert", "-p",
					"ssl", "-d", "-r", "trustRoot",
					"-k", keychain_osx, public_key_file_path,
					exception: true
				)
			end
		end

		def install_local_cert_debian(public_key_file_path)
			BoxBox.run_root_block do
				FileUtils.cp(public_key_file_path, "/usr/local/share/ca-certificates")
				system(
					"sudo", "update-ca-certificates",
					exception: true
				)
			end
		end

		def setup_ssl_cert_local(
			common_name,
			domain,
			public_key_file_path,
			private_key_file_path
		)
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				openssl_gen_cert(
					common_name, 
					domain, 
					public_key_file_path, 
					private_key_file_path
				)
				install_local_cert_osx(public_key_file_path)
			when Enums::BoxOSes::LINUX
				if File.file?("/etc/debian_version")
					openssl_gen_cert(
						common_name, 
						domain, 
						public_key_file_path, 
						private_key_file_path
					)
					install_local_cert_debian(public_key_file_path)
				else
					raise "Linux variant not setup"
				end
			else
				raise "Not implemented for #{Gem::Platform::local.os}"
			end
		end

		def setup_ssl_cert_nginx(force_replace: false)
			domain = @egg.domain_name
			if @egg.is_local?
				add_test_url_to_hosts(domain)
				public_key_file_path = "#{local_nginx_cert_path}.public.key.crt"
				private_key_file_path = "#{local_nginx_cert_path}.private.key.pem"
				clean_up_invalid_cert(domain, local_nginx_cert_name)
				if ! any_certs_matching_name_exact(domain)
					setup_ssl_cert_local(
						domain,
						domain,
						public_key_file_path,
						private_key_file_path
					)
				end
				set_firefox_cert_policy(public_key_file_path)
			else
				public_key_file_path = "#{remote_public_key}"
				private_key_file_path = "#{remote_private_key}"
				if ! File.file?(public_key_file_path) \
					|| !File.file?(private_key_file_path)\
					|| is_cert_expired(File.open(public_key_file_path).read)\
					|| force_replace
				then
					puts("downloading new certs")
					cert_hash = ssl_vars
					File.open(private_key_file_path, "w")
						.write(cert_hash["privatekey"].chomp)
					File.open(public_key_file_path, "w")
						.write(cert_hash["certificatechain"].chomp)
				end
			end
		end

		def setup_client_env_debug
			env_file = File.join(@gg.client_src, ".env.local")
			File.open(env_file, "w") do |f|
				f.puts("VITE_API_VERSION=#{@egg.api_version}")
				f.puts("VITE_BASE_ADDRESS=https://localhost:#{@egg.test_port}")
				#VITE_SSL_PUBLIC, and SSL_KEY_FILE are used by create-react-app
				#when calling `npm start`
				f.puts("VITE_SSL_PUBLIC=#{debug_cert_path}.public.key.crt")
				f.puts("VITE_SSL_PRIVATE=#{debug_cert_path}.private.key.pem")
			end
		end

		def setup_ssl_cert_local_debug
			public_key_file_path = "#{debug_cert_path}.public.key.crt"
			private_key_file_path = "#{debug_cert_path}.private.key.pem"
			clean_up_invalid_cert("#{@egg.app}-localhost")
			setup_ssl_cert_local(
				"#{@egg.app}-localhost",
				"localhost",
				public_key_file_path,
				private_key_file_path
			)
			set_firefox_cert_policy(public_key_file_path)
			setup_client_env_debug
		end
		
		def enable_nginx_include(conf_dir_include, nginx_conf_path)
			escaped_guess = Regexp.new(conf_dir_include.gsub(/\*/,"\\*"))
			BoxBox.run_root_block do
				File.open(nginx_conf_path, "r+") do |f|
					updated = f.readlines.map do |l|
						if %r{#{escaped_guess}} =~ l
							l.gsub(/^[ \t]*#/,"")
						else
							l
						end
					end * ""
					f.truncate(0)
					f.rewind
					f.write(updated)
				end
			end
		end
		
		def set_local_nginx_app_conf!(content)
			public_key_file_path = "#{local_nginx_cert_path}.public.key.crt"
			private_key_file_path = "#{local_nginx_cert_path}.private.key.pem"
			content.gsub!("<listen>","8080 ssl")
			content.gsub!("<ssl_public_key>",public_key_file_path)
			content.gsub!("<ssl_private_key>",private_key_file_path)
		end

		def set_deployed_nginx_app_conf!(content)
			content.gsub!("<listen>","[::]:443 ssl")
			content.gsub!("<ssl_public_key>",remote_public_key)
			content.gsub!("<ssl_private_key>",remote_private_key)
		end

		def update_nginx_conf(app_conf_path, port)
			BoxBox.run_root_block do
				File.open(app_conf_path, "w") do |f|
					content = @resourcerer::nginx_template
					content.gsub!(
						"<CLIENT_DEST>",
						@egg.client_dest
					)
					content.gsub!("<SERVER_NAME>", @egg.domain_name)
					content.gsub!("<API_PORT>", port.to_s)
					content.gsub!("<API_VERSION>", @egg.api_version)
					if @egg.is_local?
						set_local_nginx_app_conf!(content)
					else
						set_deployed_nginx_app_conf!(content)
					end
					f.write(content)
				end
			end
		end

		def restart_nginx
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				system("nginx -s reload", exception: true)
			when Enums::BoxOSes::LINUX
				BoxBox.restart_service("nginx")
			else
				raise "Restarting server not configured for #{Gem::Platform::local.os}"
			end
		end

		def refresh_certs
			setup_ssl_cert_nginx
			restart_nginx
		end

		def setup_nginx_confs(port)
			nginx_conf_path = get_nginx_value
			conf_dir_include = get_nginx_conf_dir_include(nginx_conf_path)
			conf_dir = get_abs_path_from_nginx_include(conf_dir_include)
			setup_ssl_cert_nginx
			enable_nginx_include(conf_dir_include, nginx_conf_path)
			update_nginx_conf("#{conf_dir}/#{@egg.app}.conf", port)
			BoxBox.run_root_block do
				system(
					"sudo",
					"rm",
					"-f",
					File.join(conf_dir, "default")
				)
			end
			restart_nginx
		end

		def startup_nginx_for_debug
			setup_nginx_confs(@egg.test_port.to_s)
			restart_nginx
		end

		def nginx_conf_location
			conf_dir_include = get_nginx_conf_dir_include
			conf_dir = get_abs_path_from_nginx_include(conf_dir_include)
			"#{conf_dir}/#{@egg.app}.conf"
		end

	end
end
