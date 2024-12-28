module SaladPrep
	module Loggable
		@@log
		@@warning_log
		@@error_log
		@@diag_log

		def log=(value)
			@@log = value
		end

		def log
			@@log
		end

		def warning_log=(value)
			@@warning_log = value
		end

		def warning_log
			@@warning_log
		end

		def error_log=(value)
			@@error_log = value
		end

		def error_log
			@@error_log
		end

		def diag_log=(value)
			@@diag_log = value
		end

		def diag_log
			@@diag_log
		end
	end
end