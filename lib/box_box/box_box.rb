require_relative "./enums"

module SaladPrep
	module BoxBox

		def self.which(cmd)
			ENV["PATH"].split(FILE::PATH_SEPARATOR).filter_map do |folder|
				path = "#{folder}/#{cmd}"
				File.executable?(path) && 
			end
		end

		def self.is_installed(cmd)
			which(cmd).any?
		end

		def self.get_package_manager
			case Gem::Platform::local.os
			when BoxOSes.LINUX
				if is_installed(PackageManagers.PACMAN)
					PackageManagers.PACMAN
				elsif is_installed(PackageManagers.APTGET)
					PackageManagers.APTGET
				end
			when BoxOSes.MACOS
				PackageManagers.HOMEBREW
			end
		end

		def self.install_package(pkg)
			puts("attempt to install #{pkg}")
			case Gem::Platform::local.os
			when BoxOSes.LINUX
				if is_installed(PackageManagers.PACMAN)
					IO.pipe do |r, w|
						spawn("yes", out: r)
						r.close
						system(
							"sudo", "-p", "Pass required for pacman install: "
							"pacman", "-S", pkg,
							in: w,
							exception: true
						)
					end
				elsif is_installed(PackageManagers.APTGET)
					system(
						"sudo", "-p", "Pass required for apt-get install: "
						"DEBIAN_FRONTEND=noninteractive", "apt-get", "-y",
						"install", pkg
						exception: true
					)
				end
			when BoxOSes.MACOS
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
	end
end