require "fileutils"
require_relative "../toob/toob"

module SaladPrep
	module FileHerder

		def self.is_path_allowed(target_dir)
			if %r{//} =~ target_dir
				Toob.error&.puts(
					"Segments seem to be missing in #{target_dir}"
				)
				return false
			end

			if target_dir == "/"
				Toob.error&.puts(
					"Segments seem to be missing in #{target_dir}"
				)
				return false
			end
			return true
		end

		def self.are_paths_allowed(*paths)
			paths.all? {|p| is_path_allowed(p)}
		end

		def self.is_dir_empty(target_dir)
			if Dir.glob("#{target_dir}/*", File::FNM_DOTMATCH).empty?
				return true
			end
			return false
		end

		def self.rm_contents_if_filled(dir_emptira)
			if ! is_dir_empty(dir_emptira)
				FileUtils.rm_rf(Dir.glob("#{dir_emptira}/*", File::FNM_DOTMATCH))
			end
			return true
		end

		def self.empty_dir(dir_replacera)
			Toob.log&.puts("Replacing #{dir_replacera}")
			if ! is_path_allowed(dir_replacera)
				raise "#{dir_replacera} has some potential errors."
			end
			result = true
			if File.directory?(dir_replacera)
				results = rm_contents_if_filled(dir_replacera)
			else
				FileUtils.mkdir_p(dir_replacera)
			end
			Toob.log&.puts("Done replacing #{dir_replacera}")
			return results
		end

		def self.cp_contents(src_dir, dest_dir)
			begin
				Toob.contain_outs do
					FileUtils.cp_r("#{src_dir}/.", dest_dir, verbose:true)
				end
			rescue Errno::EACCES
				BoxBox.run_root_block do
					Toob.contain_outs do
						system(
							"sudo", 
							"cp", 
							"-rv", 
							"#{src_dir}/.", 
							dest_dir, 
							exception: true
						)
					end
				end
			end
		end

		def self.mkdir(new_dir)
			begin
				FileUtils.mkdir_p(new_dir)
			rescue Errno::EACCES
				system(
					"sudo",
					"mkdir",
					"-p",
					new_dir,
					exception: true
				)
			end
		end

		def self.unroot(target_dir)
			begin
				Toob.contain_outs do
					FileUtils.chown_R(
						BoxBox.login_name,
						BoxBox.login_group_name,
						target_dir,
						verbose: true
					)
				end
			rescue Errno::EACCES
				BoxBox.run_root_block do
					Toob.contain_outs do
						system(
							"sudo",
							"chown",
							"-Rv",
							"#{BoxBox.login_name}:",
							target_dir
						)
					end
				end
			end
		end

		def self.cp_r(src_dir, dest_dir)
			Toob.log&.puts("copying from #{src_dir} to #{dest_dir}")
			if ! are_paths_allowed("#{src_dir}/.",dest_dir)
				raise "src_dir: #{src_dir} or dest_dir:#{dest_dir} have errors"
			end
			empty_dir(dest_dir)
			cp_contents(src_dir, dest_dir)
			unroot(dest_dir)
			Toob.log&.puts("done copying dir from #{src_dir} to #{dest_dir}")
		end

		def self.update_in_place(file_path)
			File.open(file_path, "r+") do |f|
				updated = f.readlines.map do |l|
					yield l
				end * ""
				f.truncate(0)
				f.rewind
				f.write(updated)
			end
		end


	end
end