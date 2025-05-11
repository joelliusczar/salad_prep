require "fileutils"
require_relative "../../box_box/box_box"
require_relative "../../box_box/enums"
require_relative "./spoon_phone"


module SaladPrep
	class NginxPhone < SpoonPhone

		def initialize(egg, resourcerer, where_spoon)
			@egg = egg
			@resourcerer = resourcerer
			@where_spoon = where_spoon
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
						FileUtils.mkdir_p(abs_path)
					end
				end
				return abs_path
			end
		end


		def restart_server
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				system("nginx -s reload", exception: true)
			when Enums::BoxOSes::LINUX
				BoxBox.restart_service("nginx")
			else
				raise "Restarting server not configured for #{Gem::Platform::local.os}"
			end
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
			public_key_file_path = @where_spoon.public_key
			private_key_file_path = @where_spoon.private_key
			content.gsub!("<listen>","8080 ssl")
			content.gsub!("<ssl_public_key>",public_key_file_path)
			content.gsub!("<ssl_private_key>",private_key_file_path)
		end


		def set_deployed_nginx_app_conf!(content)
			content.gsub!("<listen>","[::]:443 ssl")
			content.gsub!("<ssl_public_key>",@where_spoon.public_key)
			content.gsub!("<ssl_private_key>",@where_spoon.private_key)
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


		def nginx_conf_location
			conf_dir_include = get_nginx_conf_dir_include
			conf_dir = get_abs_path_from_nginx_include(conf_dir_include)
			"#{conf_dir}/#{@egg.app}.conf"
		end


		def setup_confs(port)
			nginx_conf_path = get_nginx_value
			conf_dir_include = get_nginx_conf_dir_include(nginx_conf_path)
			conf_dir = get_abs_path_from_nginx_include(conf_dir_include)
			enable_nginx_include(conf_dir_include, nginx_conf_path)
			update_nginx_conf("#{conf_dir}#{@egg.app}.conf", port)
			BoxBox.run_root_block do
				FileUtils.rm_f(File.join(conf_dir, "default"))
			end
		end


		def main_config_path
			nginx_conf_path = get_nginx_value
			conf_dir_include = get_nginx_conf_dir_include(nginx_conf_path)
			conf_dir = get_abs_path_from_nginx_include(conf_dir_include)
			"#{conf_dir}/#{Provincial.egg.app}.conf"
		end

	end
end