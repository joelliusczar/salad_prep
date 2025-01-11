module SaladPrep
	module Toob
		using StringEx

		@env_prefix
		@log = nil
		@warning = nil
		@error = nil
		@diag = nil
		@huge = nil
		@alt_outs

		def self.register_sub(alt_out)
			raise "Cannot redirect to stdout" if alt_out == $stdout
			if @alt_outs.nil?
				@alt_outs = [$stdout]
			end
			@alt_outs.push(alt_out)
			result = yield
			previous = @alt_outs.pop
			if @alt_outs[-1] != previous
				if ! previous.tty?
					previous.rewind
				end
				@alt_outs[-1].write(previous.read)
			end
			result
		end

		def self.access(symbol)
			value = instance_variable_get(symbol)
			if @alt_outs.nil?
				@alt_outs = [$stdout]
			end
			if @alt_outs.size > 1
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

		def self.log_dest(name="")
			value = ENV["#{@env_prefix}#{name}_LOG_DEST"]
			if value.zero?
				nil
			elsif value.downcase == "stdout" 
				$stdout
			elsif value.downcase == "stderr"
					$stderr 
			else
				File.open(value, "a")
			end
		end

		def self.set_all(env_prefix)
			@env_prefix = env_prefix
			self.log = log_dest
			self.warning = log_dest("_WARN")
			self.diag = log_dest("_DIAG")
			self.huge = log_dest("_HUGE")
			self.error = $stderr
		end

	end
end