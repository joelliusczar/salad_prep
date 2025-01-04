require_relative "../extensions/string_ex"

module SaladPrep
	module Loggable
		using StringEx

		@@log = nil
		@@warning_log = nil
		@@error_log = nil
		@@diag_log = nil
		@@huge_log = nil
		@alt_outs = [$stdout]

		def register_sub(alt_out)
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

		def self.included(other)
			other.class_eval do
				def class_variable_get(symbol)
					self.class.class_variable_get(symbol)
				end
			end
		end

		def access(symbol)
			value = class_variable_get(symbol)
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

		def log=(value)
			@@log = value
		end

		def log
			access(:@@log)
		end

		def warning_log=(value)
			@@warning_log = value
		end

		def warning_log
			access(:@@warning_log)
		end

		def error_log=(value)
			@@error_log = value
		end

		def error_log
			access(:@@error_log)
		end

		def diag_log=(value)
			@@diag_log = value
		end

		def diag_log
			access(:@@diag_log)
		end

		def huge_log=(value)
			@@huge_log = value
		end

		def huge_log
			access(:@@huge_log)
		end
	end
end