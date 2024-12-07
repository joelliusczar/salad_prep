require 'digest'

module SaladPrep
	class Libby

		def regen_lib_supports
		end

		def hash_index_dir(input_dir)
			Enumerator.new do |yielder|
				Dir.glob("**/*",File::FNM_DOTMATCH, base: input_dir)
				.sort_by { |e| e }.each do |file|
					script_name = file.split(".")[-2]
					next if script_name.zero?
					enum_name = script_name
						.gsub(/[^[:alnum:]]/, "_")
						.tr_s("_","_")
						.upcase
					full_path = File.join(input_dir, file)
					sha256 = Digest::SHA256.file(full_path)
					yielder << [file, enum_name, sha256.hexdigest]
				end
			end
		end

	end
end