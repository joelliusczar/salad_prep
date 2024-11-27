require "fileutils"
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

		def self.rm_contents_if_filled(dir_emptira)
			if ! is_dir_empty
				FileUtils.rm_rf("#{dir_emptira}/")
			end
			return true
		end

		def self.empty_dir(dir_replacera)
			puts("Replacing #{dir_replacera}")
			if ! is_path_allowed(dir_replacera)
				raise "#{dir_replacera} has some potential errors."
			end
			result = true
			if File.exist?(dir_replacera)
				results = rm_contents_if_filled(dir_replacera)
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
			FileUtils.cp_r(src_dir, dest_dir, verbose:true)
			puts("done copying dir from ${src_dir} to ${dest_dir}")
		end
	end
end