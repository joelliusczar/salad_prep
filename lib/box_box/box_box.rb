require_relative "./enums"
require_relative "../strink/strink"

module SaladPrep
	using Strink

	class BoxBox

		def initialize(egg)
			@egg = egg
		end

		def self.which(cmd)
			ENV["PATH"].split(File::PATH_SEPARATOR).filter_map do |folder|
				path = "#{folder}/#{cmd}"
				File.executable?(path) ? path : nil
			end
		end

		def self.uses_aptget?
			which(Enums::PackageManagers::APTGET).any?
		end

		def self.is_installed?(pkg)
			system(pkg, "--version", out: File::NULL, err: File::NULL) ||
			system(pkg, "-v", out: File::NULL, err: File::NULL) ||
			system(pkg, "-V", out: File::NULL, err: File::NULL) ||
			which(pkg).any? ||
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if uses_aptget?
					system("dpkg", "-s", pkg, out: File::NULL, err: File::NULL)
				else
					raise "Non-debian distros not configured"
				end
			when Enums::BoxOSes::MACOS
				raise "Mac not configured"
			end
		end

		def self.get_package_manager
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if is_installed(Enums::PackageManagers::PACMAN)
					Enums::PackageManagers::PACMAN
				elsif is_installed(Enums::PackageManagers::APTGET)
					Enums::PackageManagers::APTGET
				end
			when Enums::BoxOSes::MACOS
				Enums::PackageManagers::HOMEBREW
			end
		end

		def self.install_package(pkg, input: "yes")
			puts("attempt to install #{pkg}")
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if is_installed(PackageManagers.PACMAN)
					IO.pipe do |r, w|
						spawn("yes", input, out: r)
						r.close
						system(
							"pacman", "-S", pkg,
							in: w,
							exception: true
						)
					end
				elsif is_installed(PackageManagers.APTGET)
					system(
						"DEBIAN_FRONTEND=noninteractive", "apt-get", "-y",
						"install", pkg,
						exception: true
					)
				end
			when Enums::BoxOSes::MACOS
				IO.pipe do |r, w|
					spawn("yes", out: r)
					r.close
					system(
						"brew", "install", pkg,
						in: w,
						exception: true
					)
				end
			end
		end

		def self.install_if_missing(pkg)
			if ! BoxBox.is_installed?(pkg)
				BoxBox.install_package(pkg)
			end
		end

		def self.update_pkg_mgr
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if is_installed(PackageManagers.APTGET)
					system("apt-get update", exception: true)
				end
			when Enums::BoxOSes::MACOS
				if ! system("brew --version 2>/dev/null")
					#-f = -fail - fails quietly, i.e. no error page ...I think?
					#-s = -silent - don\'t show any sort of loading bar or such
					#-S = -show-error - idk
					#-L = -location - if page gets redirect, try again at new location
					url = File.join(
						"https://raw.githubusercontent.com",
						"/Homebrew/install/HEAD/install.sh"
					)
					
					script = <<~CALL
						/bin/bash -c "$(curl -fsSL \
							#{url})"
					CALL
					system(script, exception: true)
				end
			else
				raise "OS is not setup"
			end
		end

		def self.restart_service(service)
			if system("systemctl", "is-active", --"quiet", service)
				system("systemctl", "restart", service, exception: true)
			else
				system("systemctl", "enable", service, exception: true)
				system("systemctl", "start", service, exception: true)
			end
		end

		def self.path_append(segment)
			profile = File.join(
				ENV["HOME"],
				".profile"
			)
			File.open(profile, "r+") do |file|
				content = file.read
				if ! (content =~ /PATH=(?:.*:)#{Regexp.quote(segment)}(?::.)*/)
					current_path = ENV["PATH"]
					file.write("PATH=#{current_path}:#{segment}")
				end
			end
			`. "$HOME"/.profile >/dev/null 2>&1 && env`
				.split("\n")
				.each do |e|
					pair = e.split("=")
					ENV[pair[0]] = pair[1]
				end
		end

		def self.run_and_get(cmds, in_s:nil, exception: false)
			result = IO.popen(
				cmds,
				"r+"
			) do |p|
				if in_s.populated?
					p.write(in_s)
				end
				p.close_write
				output = p.read
			end
			if exception && ! $?.success?
				raise "#{cmds[0]} failed with exit code #{$?.exitstatus}"
			end
		end

		def self.kill_process_using_port(port)
			if system("ss -V", out: File::NULL, err: File::NULL)
				procId = run_and_get(
					["ss", "-lpn", "sport = :#{port}"],
					exception: true
				)
				if procId.populated?
					Process.kill(15, procId)
				end
			elsif system("lsof -v", out: File::NULL, err: File::NULL)
				procId = run_and_get(
					["lsof", "-i", ":#{port}"],
					exception: true
				).split("\n")[1].split[1]
				if procId.populated?
					Process.kill(15, procId)
				end
			else
				raise "Script not wired up to be able to kill process at port: #{port}"
			end
		end

	end
end