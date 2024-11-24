module SaladPrep
	module ArgChecker

		def env_prefix(value)
			if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ @env_prefix)
				raise "env prefix is using an illegal form. "
					"Please use begin with letter and only use alphanumeric "
					"for rest with a max length of 6"
			end
		end

		def path(value)
			if ! (/^['"``]+/ =~ @env_prefix)
				raise "segment is using illegal characters"
			end
		end
 
	end
end