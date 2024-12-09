require "fileutils"

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

		def self.rm_contents_if_filled(dir_emptira)
			if ! is_dir_empty(dir_emptira)
				FileUtils.rm_rf("#{dir_emptira}/*")
			end
			return true
		end

		def self.empty_dir(dir_replacera)
			puts("Replacing #{dir_replacera}")
			if ! is_path_allowed(dir_replacera)
				raise "#{dir_replacera} has some potential errors."
			end
			result = true
			if File.directory?(dir_replacera)
				results = rm_contents_if_filled(dir_replacera)
			else
				FileUtils.mkdir_p(dir_replacera)
			end
			puts("Done replacing #{dir_replacera}")
			return results
		end

		def self.copy_dir(src_dir, dest_dir)
			puts("copying from #{src_dir} to #{dest_dir}")
			if ! are_paths_allowed("#{src_dir}/.",dest_dir)
				raise "src_dir: #{src_dir} or dest_dir:#{dest_dir} have errors"
			end
			empty_dir(dest_dir)
			FileUtils.cp_r("#{src_dir}/.", dest_dir, verbose:true)
			puts("done copying dir from #{src_dir} to #{dest_dir}")
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