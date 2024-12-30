require "fileutils"
require_relative "../box_box/box_box"
require_relative "../file_herder/file_herder"
require_relative "../extensions/string_ex"

module SaladPrep
	using StringEx

	class BrickStack

		def initialize(egg)
			@egg = egg
		end

		def setup_app_directories
			FileUtils.mkdir_p("#{@egg.app_root}/#{@egg.app_trunk}")
			FileUtils.mkdir_p("#{@egg.app_root}/keys")
			FileUtils.mkdir_p(@egg.config_dir)
			FileUtils.mkdir_p(@egg.build_dir)
		end

		def env_api_content
			content = ""
			@egg.env_hash(include_dirs: true).each_pair do |key, value|
				content ^= "#{key}='#{value}'"
			end
			content
		end

		def setup_env_api_file
			puts("setting up .env file")
			env_file = "#{@egg.config_dir}/.env"
			env_file_src = "#{@egg.templates_src}/.env_api"
			if !FileHerder::is_path_allowed(env_file)
				raise "env_file file path has potential errors: #{env_file}"
			end
			contents = env_api_content
			File.open(env_file, "w") { |f| f.write(contents)}
		end

		def create_install_directory
			FileUtils.mkdir_p(@egg.repo_path)
		end

		def setup_build(current_branch: nil)
			@egg.load_env
			required_env_vars = @egg.server_env_check_required.map do |e|
				"Required var #{e} not set"
			end

			if required_env_vars.any?
				raise required_env_vars.join("\n")
			end

			create_install_directory

			BoxBox.install_if_missing("git")

			FileUtils.rm_rf(@egg.repo_path)

			Dir.chdir(@egg.build_dir) do 
				system(
					"git", "clone", @egg.repo_url, @egg.project_name_snake,
					exception: true
				)
				Dir.chdir(@egg.project_name_snake) do
					if current_branch != "main"
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