require "etc"
require "open3"
require "tempfile"
require_relative "./enums"
require_relative "../extensions/string_ex"
require_relative "../extensions/object_ex"
require_relative "../toob/toob"

module SaladPrep
	class BoxBox
		using StringEx
		using ObjectEx

		ROOT_UID = 0

		def initialize(egg)
			@egg = egg
		end

		def self.login_name
			ENV["SUDO_USER"] || Etc.getlogin
		end

		def self.login_id
			(ENV["SUDO_UID"] || Process::UID.from_name(login_name)).to_i
		end

		def self.login_group_id
			(ENV["SUDO_GID"] || Etc.getpwuid(login_id).gid).to_i
		end

		def self.login_group_name
			Etc.getpwuid(login_group_id).name
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
				if is_installed?(Enums::PackageManagers::PACMAN)
					Enums::PackageManagers::PACMAN
				elsif is_installed?(Enums::PackageManagers::APTGET)
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
				if is_installed?(Enums::PackageManagers::PACMAN)
					IO.pipe do |r, w|
						spawn("yes", input, out: r)
						r.close
						run_root_block do
							system(
								"pacman", "-S", pkg,
								in: w,
								exception: true
							)
						end
					end
				elsif is_installed?(Enums::PackageManagers::APTGET)
					run_root_block do
						system(
							{ "DEBIAN_FRONTEND" => "noninteractive"},
							"apt-get", "-y",
							"install", pkg,
							exception: true
						)
					end
				end
			when Enums::BoxOSes::MACOS
				IO.pipe do |r, w|
					spawn("yes", out: r)
					r.close
					run_root_block do
						system(
							"brew", "install", pkg,
							in: w,
							exception: true
						)
					end
				end
			end
		end

		def self.install_if_missing(pkg)
			if ! BoxBox.is_installed?(pkg)
				run_root_block do
					BoxBox.install_package(pkg)
				end
			end
		end

		def self.update_pkg_mgr
			case Gem::Platform::local.os
			when Enums::BoxOSes::LINUX
				if is_installed?(Enums::PackageManagers::APTGET)
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
			run_root_block do
				if system("systemctl", "is-active", --"quiet", service)
					system("systemctl", "restart", service, exception: true)
				else
					system("systemctl", "enable", service, exception: true)
					system("systemctl", "start", service, exception: true)
				end
			end
		end

		def self.process_path_append(segment)
			if ! ENV["PATH"].include?(segment)
				ENV["PATH"] += ":#{segment}"
			end
		end

		def self.path_append(segment)
			profile = File.join(
				ENV["HOME"],
				".profile"
			)
			File.open(profile, "r+") do |file|
				content = file.read
				if ! (content =~ /PATH=(?:.*:)'?#{Regexp.quote(segment)}'?(?::.)*/)
					current_path = ENV["PATH"]
					file.puts("PATH=\"$PATH\":'#{segment}'")
				end
			end
			`. "$HOME"/.profile >/dev/null 2>&1 && env`
				.split("\n")
				.each do |e|
					pair = e.split("=")
					ENV[pair[0]] = pair[1]
				end
		end

		def self.__script_arg_juggle__(*args, **options)
			cmd_arr = ["sh", "-c"]
			if options.fetch(:avoid_root, true)
				#E preserves the env
				cmd_arr.insert(0, "sudo","-E","-u", login_name,)
			end
			if args.length == 1
				if ! args[0].kind_of?(String)
					raise "No script or command provided"
				end
				cmd_arr.push(args[0])
			elsif args.length == 2
				if ! args[0].kind_of?(Hash)
					raise "first argument is expected to be a hash."
				end
				if ! args[1].kind_of?(String)
					raise "No script or command provided"
				end
				env_args = args[0].map do |k,v|
					"#{k.to_s}=#{v.to_s}"
				end
				if options.fetch(:avoid_root, true)
					#insert before sh
					# [sudo, -E, -u, login_name, ^right here^, sh, -c, script]
					cmd_arr.insert(-3, *env_args) 
				else
					cmd_arr.insert(0, args[0])
				end
				cmd_arr = [*cmd_arr, args[1]]
			else
				raise "Too many arguments provided. Expected 1 or 2."
			end
			Toob.diag&.puts("process: #{cmd_arr} with options #{options}")
			yield(*cmd_arr, **options)
		end

		def self.__script_wrap__(*args, **options, &block)
			if args.zero?
				raise "No arguments provided. 1 or 2 expected."
			end

			if options.include?(:in) && options.include?(:in_s)
				raise <<~ERR
					:in and :in_s are mutually exclusive and cannot 
					be passed to the same call.
				ERR
			end

			if options.include?(:in_s)
				IO.pipe do |r,w|
					w.write(options[:in_s])
					w.close
					options_to_pass = options.to_h do |k, v|
						return [:in, r] if k == :in_s
						return [k,v]
					end
					__script_arg_juggle__(*args, **options_to_pass, &block)
				end
			else
				__script_arg_juggle__(*args, **options, &block)
			end
		end

		def self.script_run(*args, **options)
			__script_wrap__(*args, **options) do |*args1, **options1|
				system(
					*args1,
					**options1
				)
			end
		end

		def self.script_spawn(*args, **options)
			__script_wrap__(*args, **options) do |*args1, **options1|
				spawn(
					*args1,
					**options1
				)
			end
		end

		def self.run_and_put(*cmds, in_s:nil, exception: false)
			IO.pipe do |r,w|
				w.write(in_s)
				w.close
				system(*cmds, in: r, exception:)
			end
		end

		def self.run_and_get(*cmds, in_s:nil, err: nil, exception: false)
			Tempfile.create do |tmp|
				Toob.register_sub(tmp) do
					result = Open3.popen3(
						*cmds
					) do |i, o, e, t|
						out_lines = []
						err_lines = []
						if in_s.populated?
							Thread.new do
								i.write(in_s)
								i.close
							end
						end
					
						ot = Thread.new do
							until (line = o.gets).nil?
								out_lines.push(line)
							end
						end
					
						et =Thread.new do
							until (line = e.gets).nil?
								err_lines.push(line)
							end
						end
						
						t.join
						ot.join
						et.join
						if t.value.exitstatus == 0
							if err_lines.populated?
								Toob.error&.puts("errors on success:")
								Toob.error&.puts(err_lines * "")
								Toob.error&.puts("_" * 12)
							end
							out_lines * ""
						else
							Toob.log&.puts(out_lines * "")
							if exception
								raise <<~ERR_MSG
									#{err_lines * ""}
									#{"#" * 20}
									#{cmds[0]} failed with exit code #{t.value.exitstatus}
								ERR_MSG
							end
							
						end
					end
				end
			end

		end

		def self.kill_process_using_port(port)
			if system("ss -V", out: File::NULL, err: File::NULL)
				run_root_block do
					result = run_and_get(
						"ss", "-lpn", "sport = :#{port}",
						exception: true
					)
					match = result&.match(/pid=(\d+)/)
					procId = match.embodied? ? match[1] : nil
					if procId.populated?
						Process.kill(15, procId.to_i)
					end
				end
			elsif system("lsof -v", out: File::NULL, err: File::NULL)
				run_root_block do
					procId = run_and_get(
						"lsof", "-i", ":#{port}",
						exception: true
					).split("\n")[1].split[1]
					if procId.populated?
						Process.kill(15, procId.to_i)
					end
				end
			else
				raise "Script not wired up to be able to kill process at port: #{port}"
			end
		end

		def self.run_root_block
			if Process.uid != ROOT_UID
				raise "This section requires script to be run as root"
			end
			if @root_count.nil?
				@root_count = 1
			else
				@root_count += 1
			end
			Process::Sys.seteuid(ROOT_UID)
			Process::Sys.setegid(ROOT_UID)
			result = yield
			@root_count -= 1
			if @root_count == 0
				Process::Sys.setegid(login_group_id)
				Process::Sys.seteuid(login_id)
			end
			result
		end

		def setup_app_directories
			FileUtils.mkdir_p("#{@egg.app_root}/#{@egg.app_trunk}")
			FileUtils.mkdir_p("#{@egg.app_root}/keys")
			FileUtils.mkdir_p(@egg.config_dir)
			FileUtils.mkdir_p(@egg.build_dir)
		end

		def setup_env_api_file(overrides = {})
			Toob.log&.puts("setting up .env file")
			env_file = "#{@egg.config_dir}/.env"
			env_file_src = "#{@egg.templates_src}/.env_api"
			if !FileHerder.is_path_allowed(env_file)
				raise "env_file file path has potential errors: #{env_file}"
			end
			contents = ""
			@egg.env_hash(include_dirs: true).merge(overrides)
				.each_pair do |key, value|
				contents ^= "#{key}='#{value}'"
			end
			File.open(env_file, "w") { |f| f.write(contents)}
		end

		def create_install_directory
			FileUtils.mkdir_p(@egg.repo_path)
		end

		def setup_build_dir(current_branch: nil)
			@egg.load_env
			Toob.diag&.puts("current_branch: #{current_branch}")
			required_env_vars = @egg.server_env_check_required.map do |e|
				"Required var #{e} not set"
			end

			if required_env_vars.any?
				raise required_env_vars.join("\n")
			end

			create_install_directory

			BoxBox.install_if_missing("git")

			FileUtils.rm_r(File.join(@egg.build_dir, @egg.project_name_snake))

			Dir.chdir(@egg.build_dir) do 
				system(
					"git", "clone", @egg.repo_url, @egg.project_name_snake,
					exception: true
				)
				Dir.chdir(@egg.project_name_snake) do
					if current_branch.populated? && current_branch != "main"
						system(
							"git", "checkout", "-t" , "origin/#{current_branch}",
							exception: true
						)
					end
				end
			end
		end

	end
end
