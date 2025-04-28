require_relative "../extensions/string_ex"
require_relative "../extensions/object_ex"

module SaladPrep

	class SanitizedFile
		def initialize(file, sanitized_words = [])
			@sanitized_words = sanitized_words
			@file = file
		end

		def sanitize_string(s)
			s2 = s
			@sanitized_words.each do |w|
				s2 = s2.gsub(w, "***")
			end
			s2
		end

		def sanitize(o)
			if o.kind_of?(String)
				sanitize_string(o)
			elsif o.kind_of?(Array)
				raise "We don't want to process arrays through the diagnostic channel"
			else
				sanitize_string(o.to_s)
			end
		end

		def puts(*objects)
			@file.puts(objects.map{|o| sanitize(o)})
		end

		def print(*objects)
			@file.print(objects.map{|o| sanitize(o)})
		end

		def write(*objects)
			@file.write(objects.map{|o| sanitize(o)})
		end

		def rewind
			@file.rewind
		end
		
	end

	module Toob
		using StringEx
		using ObjectEx

		@env_prefix
		@log = nil
		@warning = nil
		@error = nil
		@diag = nil
		@huge = nil
		@alt_outs = []
		@sanitize_outputs = true


		def self.register_sub(alt_out)
			raise "Cannot redirect to stdout" if alt_out == $stdout
			if @alt_outs.nil?
				@alt_outs = []
			end
			@alt_outs.push(alt_out)
			result = yield
			previous = @alt_outs.pop
			if @alt_outs[-1] != previous && @alt_outs[-1].embodied?
				if ! previous.tty?
					previous.rewind
				end
				@alt_outs[-1].write(previous.read)
			end
			result
		end

		def self.contain_outs
			if @alt_outs.populated?
				if @contain_count.nil?
					@contain_count = 1
				else
					@contain_count += 1
				end
				old_out = $stdout
				$stdout = @alt_outs[-1]
				result = yield
				@contain_count -= 1
				if @contain_count == 0
					$stdout = old_out
				end
				result
			else
				yield
			end
		end

		def self.access(symbol)
			value = instance_variable_get(symbol)
			if @alt_outs.nil?
				@alt_outs = []
			end
			if @alt_outs.populated?
				if value == $stdout
					@alt_outs[-1]
				else
					value
				end
			else
				value
			end
		end

		def self.log=(value)
			@log = value
		end

		def self.log
			access(:@log)
		end

		def self.warning=(value)
			@warning = value
		end

		def self.warning
			access(:@warning)
		end

		def self.error=(value)
			@error = value
		end

		def self.error
			access(:@error)
		end

		def self.diag=(value)
			@diag = value
		end

		def self.diag
			access(:@diag)
		end

		def self.huge=(value)
			@huge = value
		end

		def self.huge
			access(:@huge)
		end



		def self.log_dest(name="", filename: "", sanitized_words: [])
			value = ENV["#{@env_prefix}#{name}_LOG_DEST"].or_blank || filename
			
			if value.zero?
				nil
			elsif value.downcase == "stdout" 
				$stdout
			elsif value.downcase == "stderr"
					$stderr 
			else
				file = File.open(value, "a")
				if sanitized_words.populated?
					return SanitizedFile.new(file, sanitized_words)
				end
				file
			end
		end

		def self.set_all(
			env_prefix,
			sanitized_words: [],
			log_dest_override: "",
			warning_dest_override: "",
			diag_dest_override: "",
			huge_dest_override: ""
		)
			@env_prefix = env_prefix
			@sanitized_words = sanitized_words
			self.log = log_dest(filename: log_dest_override)
			self.warning = log_dest("_WARN", filename: warning_dest_override)
			self.diag = log_dest(
				"_DIAG",
				filename: diag_dest_override,
				sanitized_words:
			)
			self.huge = log_dest(
				"_HUGE",
				filename: huge_dest_override,
				sanitized_words:
			)
			self.error = $stderr
		end

	end
end