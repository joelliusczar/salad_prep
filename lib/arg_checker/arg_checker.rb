module SaladPrep
	module ArgChecker

		class << self
			def env_prefix(value)
				if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ value)
					raise "env prefix is using an illegal form. "
						"Please use begin with letter and only use alphanumeric "
						"for rest with a max length of 6"
				end
			end
	
			def api_version(value)
				if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ value)
					raise <<~MSG
						api version is using an illegal form.
						Please use begin with letter and only use alphanumeric 
						for rest with a max length of 6
					MSG
				end
			end

			def pkg_version(value)
				if ! (/\d+\.\d+(?:\.\d+)?/ =~ value)
					raise <<~MSG
						version is using an illegal form.
						Please use numbers seperated by dots
					MSG
				end
			end

			def quote_check(value)
				if ! (/[^'"`]+/ =~ value)
					raise "value #{value} is using illegal characters"
				end
			end
	
			def db_name(value)
				if ! (/[a-zA-Z0-9_]{1,100}/ =~ value)
					raise "db_name #{value} is using illegal characters"
				end
			end

			alias_method :path, :quote_check

		end
 
	end
end