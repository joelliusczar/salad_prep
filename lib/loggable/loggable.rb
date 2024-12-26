module SaladPrep
	module Loggable
		@@log

		def log=(value)
			@@log = value
		end

		def log
			@@log
		end
	end
end