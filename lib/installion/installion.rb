require "fileutils"
require_relative "../box_box/box_box"
require_relative "../box_box/enums"
require_relative "../dbass/myass_root"
require_relative "../resorcerer/resorcerer"

module SaladPrep
	class Installion

		def initialize(egg)
			@egg = egg
		end

		def install_dependencies
			raise "install_dependencies not implemented"
		end

		def self.asdf(root: false)
			BoxBox.run_and_put(
				"sudo",
				"bash",
				"-sl",
				in_s: Resorcerer.bootstrap_install(root:),
				exception: true
			)
		end

		def install_local_dependencies
			self.class.asdf
		end

		def root_install
			self.class.asdf
		end

		def self.curl
			system("curl -V", exception: true)
		end

		def self.python(egg, monty)
			if ! BoxBox.is_installed?(monty.python_command) \
				|| monty.is_installed_version_good?
			then
				python_to_link = "python3"
				case Gem::Platform::local.os
				when Enums::BoxOSes::LINUX
					BoxBox.install_if_missing("python3")
					if ! monty.is_installed_version_good?
						BoxBox.install_if_missing("python#{monty.version}")
						python_to_link = "python#{monty.version}"
					end
				when Enums::BoxOSes::MACOS
				else
					raise "OS is not configured for installing python"
				end
				unless File.directory?(egg.bin_dir)
					FileUtils.mkdir_p(egg.bin_dir)
				end
				FileUtils.ln_sf(
					BoxBox.which(python_to_link).first,
					File.join(egg.bin_dir, monty.python_command)
				)
				BoxBox.path_append(egg.bin_dir)
			end
		end

		def self.python_pip(egg, monty)
			if ! system(
				monty.python_command, "-m", "pip", "-V",
				out: File::NULL, err: File::NULL
			)
			then
				if BoxBox.uses_aptget?
					BoxBox.install_package("python3-pip")
				else
					output_path = File.join(
						egg.build_dir,
						"get-pip.py"
					)
					system(
						"curl", 
						"-o",
						output_path,
						"https://bootstrap.pypa.io/pip/get-pip.py",
						exception: true
					)
					system(monty.python_command, output_path, exception: true)
				end
			end
		end

		def self.python_virtualenv(monty)
			BoxBox.install_if_missing("python3-virtualenv")
		end

		def self.python_full(egg, monty)
			python(egg, monty)
			python_pip(egg, monty)
			python_virtualenv(monty)
		end

		def self.nodejs(node_version)
			if ! `asdf plugin list`.include?("nodejs")
				system(
					"asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git",
					exception: true
				)
			end
			if ! system("asdf", "list", "nodejs", node_version)
				system(
					"asdf", "install", "nodejs", node_version,
					exception: true
				)
			end
		end

		def self.mariadb(pass)
			if ! BoxBox.is_installed?("mariadb")
				case Gem::Platform::local.os
				when Enums::BoxOSes::LINUX
					if BoxBox.uses_aptget?
						BoxBox.install_package("mariadb-server")
					else
						raise "Distro is not configured for installing mariadb"
					end
				when Enums::BoxOSes::MACOS
					BoxBox.install_package("mariadb")
				else
					raise "OS is not configured for installing mariadb"
				end
			end
			if ! MyAssRoot.is_root_pass_set?
				MyAssRoot.revoke_default_db_accounts
				MyAssRoot.set_db_root_initial_password(pass)
			end
		end

		def self.sqlite
			BoxBox.install_if_missing("sqlite3")
		end

		def self.openssl
			if BoxBox.uses_aptget?
				BoxBox.install_if_missing("openssl")
			end
		end

		def self.ca_certificates
			if BoxBox.uses_aptget?
				BoxBox.install_if_missing("ca-certificates")
			end
		end

		def self.nginx()
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if BoxBox.uses_aptget?
					BoxBox.install_package("nginx-full")
				else
					raise "Distro is not configured for installing nginx"
				end
			when Enums::BoxOSes::MACOS
				BoxBox.install_if_missing("nginx")
			else
				raise "OS is not configured for installing nginx"
			end
		end

		def self.nginx_and_setup(egg, w_spoon)
			nginx
			conf_dir_include = w_spoon.get_nginx_conf_dir_include
			conf_dir = w_spoon.get_abs_path_from_nginx_include(conf_dir_include)
			conf_path = File.join(
				conf_dir,
				"#{egg.app}.conf"
			)
			if ! File.exist?(conf_path)
				w_spoon.setup_nginx_confs(egg.api_port.to_s)
				File.open(
					File.join(conf_dir, "nginx_evil.conf"), "w"
				).write(Resorcerer.nginx_evil_conf)
			end
		end

	end
end