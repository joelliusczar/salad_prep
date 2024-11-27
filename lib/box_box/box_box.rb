require_relative "./enums"

module SaladPrep
	class BoxBox

		def initialize(egg)
			@egg = egg
		end

		def self.which(cmd)
			ENV["PATH"].split(File::PATH_SEPARATOR).filter_map do |folder|
				path = "#{folder}/#{cmd}"
				File.executable?(path)
			end
		end

		def self.is_installed(cmd)
			which(cmd).any?
		end

		def self.get_package_manager
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if is_installed(PackageManagers.PACMAN)
					Enums::PackageManagers::PACMAN
				elsif is_installed(PackageManagers.APTGET)
					PackageManagers.APTGET
				end
			when Enums::BoxOSes::MACOS
				PackageManagers.HOMEBREW
			end
		end

		def self.install_package(pkg)
			puts("attempt to install #{pkg}")
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if is_installed(PackageManagers.PACMAN)
					IO.pipe do |r, w|
						spawn("yes", out: r)
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

		def update_env_path
			unless ENV["PATH"].include?(@egg.bin_dir)

			end
		end

	end
end