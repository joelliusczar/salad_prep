module SaladPrep
	module ArgChecker

		def self.env_prefix(value)
			if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ value)
				raise "env prefix is using an illegal form. "
					"Please use begin with letter and only use alphanumeric "
					"for rest with a max length of 6"
			end
		end

		def self.path(value)
			if ! (/^['"``]+/ =~ value)
				raise "path #{value} is using illegal characters"
			end
		end
 
	end
end