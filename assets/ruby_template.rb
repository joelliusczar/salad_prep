
setup_lvl = "<%= setup_lvl %>"
current_branch = "<%= current_branch %>"

if ! Provincial.far_port.is_ssh?
	raise "This section should only be run remotely"
end

puts("Server environmental variable check")
Provincial.egg.server_env_check_recommended.each do |e|
	puts("Recomended var #{e} not set")
end

required_env_vars = Provincial.egg.server_env_check_required.map do |e|
	"Required var #{e} not set"
end

if required_env_vars.any?
	raise required_env_vars.join("\n")
end

Provincial.brick_stack.create_install_directory

if ! system("git --version", out: File::NULL, err: File::NULL)
	BoxBox::install_package("git")
end

FileUtils.rm_rf(Provincial.egg.repo_path)

Dir.chdir(Provincial.egg.build_dir) do 
	system(
		"git", "clone", Provincial.egg.repo_url, Provincial.egg.project_name_snake,
		exception: true
	)
	Dir.chdir(Provincial.egg.project_name_snake) do
		if current_branch != "main"
			system(
				"git", "checkout", "-t" , "origin/#{current_branch}",
				exception: true
			)
		end
	end
end

Provincial.far_port.remote_setup_path(setup_lvl)