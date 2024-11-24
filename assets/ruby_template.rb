
setup_lvl = "<%= setup_lvl %>"
current_branch = "<%= current_branch %>"

raise "This section should only be run remotely" unless far_port.is_ssh?

raise "missing keys on server" unless egg.server_env_check

brick_stack.create_install_directory

if ! system("git --version", out: File::NULL, err: File::NULL)
	BoxBox::install_package("git")
end

FileUtils.rm_rf(egg.repo_path)

Dir.chdir(File.join(egg.app_root, egg.build_dir)) do 
	system(
		"git", "clone", egg.repo_url, egg.project_name_snake,
		exception: true
	)
	Dir.chdir(egg.project_name_snake) do
		if current_branch != "main"
			system(
				"git", "checkout", "-t" , "origin/#{current_branch}",
				exception: true
			)
		end
	end
end

far_port.remote_setup_path(setup_lvl)