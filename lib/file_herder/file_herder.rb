require "etc"
require_relative "../strink/strink.rb"

module SaladPrep
	module FileHerder

		def self.is_path_allowed(target_dir)
			if %r{//} =~ target_dir
				puts("Segments seem to be missing in #{target_dir}")
				return false
			end

			if target_dir == "/"
				puts("Segments seem to be missing in #{target_dir}")
				return false
			end
			return true
		end

		def self.are_paths_allowed(*paths)
			paths.all? {|p| is_path_allowed(p)}
		end

		def self.is_dir_empty(target_dir)
			if Dir["#{target_dir}/*"].empty?
				return true
			end
			return false
		end

		def self.sudo_rm_dir(dir_emptira, contents_only: true)
			dir_emptira = if Strink::empty_s?(dir_emptira)
					"#{dir_emptira}/"
				else 
					dir_emptira
				end
			if ! File.exists?(dir_emptira)
				raise "path: #{dir_emptira} does not exist"
			end
			FileUtils.rm_rf(dir_emptira)
			return true
			rescue SystemCallError
				prompt = "Password required to remove files from #{dir_emptira}: "
				if ! system("sudo -p #{prompt} rm -rf '#{dir_emptira}'")
					raise "Failed to fully remove everything in #{dir_emptira}"
				end
			end
		end

		def self.sudo_cp_contents(src_dir, dest_dir)
			if ! File.exists?(src_dir) || ! File.exists?(dest_dir) 
				raise "#{src_dir} or #{dest_dir} does not exist"
			end
			begin
				FileUtils.cp_r(src_dir, dest_dir, verbose:true)
				return true
			rescue SystemCallError
				prompt = "Password required to copy files"
				if ! system("sudo -p #{prompt} cp -rv '#{dir_emptira}'")
					raise "Failed to copy all contents from #{src_dir} to #{dest_dir}"
				end
		end

		def self.rm_contents_if_filled(dir_emptira)
			if ! is_dir_empty
				return sudo_rm_dir(dir_emptira, contents_only: true)
			end
			return true
		end

		def self.empty_dir(dir_replacera)
			puts("Replacing #{dir_replacera}")
			if ! is_path_allowed(dir_replacera)
				raise "#{dir_replacera} has some potential errors."
			end
			result = true
			if file.exists?(dir_replacera)
				results = rm_contents_if_filled(dir_replacera)
			end
			puts("Done replacing #{dir_replacera}")
			return results
		end

		def self.unroot_dir(dir_unrootura, current_user)
			if ! File.exists?(dir_unrootura)
				raise "path: #{dir_unrootura} does not exist"
			end
			if ! Etc.getpwnam(current_user)
				raise "user: #{current_user} does not exist"
			end
			prompt = "Password required to change owner of #{dir_unrootura}"
			if ! system(
				"sudo -p #{prompt} chown -R '#{current_user}': '#{dir_unrootura}'"
			)
				raise "Failed to change owner of #{dir_unrootura}"
			end
		end

		def self.copy_dir(src_dir, dest_dir, current_user)
			puts("copying from #{src_dir} to #{dest_dir}")
			if ! are_paths_allowed("#{src_dir}/.",dest_dir)
				raise "src_dir: #{src_dir} or dest_dir:#{dest_dir} have errors"
			end
			empty_dir(dest_dir)
			sudo_cp_contents(src_dir, dest_dir)
			unroot_dir(dest_dir, current_user)
			puts("done copying dir from ${src_dir} to ${dest_dir}")
		end
	end
end