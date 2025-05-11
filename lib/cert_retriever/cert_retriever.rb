module SaladPrep
	class CertRetriever
		def initialize(egg)
			@egg = egg
		end

		def ssl_vars(force: false)
			raise "ssl_vars not implemented"
		end

		
	end
end