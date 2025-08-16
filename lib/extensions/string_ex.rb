module SaladPrep
	module StringEx

		LOW = :low
		UP = :up

		refine Object do
			def zero?
				return true if self.nil?
				if self.respond_to?(:empty?)
					return true if self.empty?
				end
				return false
			end

			def populated?
				! zero?
			end

			def true?
				if kind_of?(String)
					downcase == "true"
				else
					false
				end
			end

			def or_blank
				if self == ""
					nil
				else
					self
				end
			end

		end

		refine String do
			def to_snake(casing = nil)
				casing = casing ? casing.to_sym() : nil
		
				project_name = self.split(
						/
							(?<=[A-Z])(?=[A-Z][a-z])
							|(?<=[^A-Z])(?=[A-Z])
							|(?<=[A-Za-z])(?=[^A-Za-z])
						/x
					)
					.map(&:strip)
					.join("_")
					.delete("^a-zA-Z0-9 _-")
					.tr(" -","_")
		
				if casing == LOW
					project_name.downcase!
				end
		
				if casing == UP
					project_name.upcase!
				end
		
				return project_name
			end

			def ^(other)
				self + "\n" + other
			end

			def instancify
				return self if start_with?("@") 
				"@#{to_s}"
			end

			def r_shift(tabs = 1)
				split.split("\n") * ("\n" + ("\t" * tabs))
			end

			def home_sub
				start_with?("~") ? sub("~", ENV["HOME"]) : self
			end

			def domain_name_check
				if ! (/^[a-zA-Z0-9_\-\.]+$/ =~ self)
					raise "domain_name #{self} is using illegal characters"
				end
			end

			def quote_check
				if ! (/^[^'"`]+$/ =~ self)
					raise "value #{self} is using illegal characters"
				end
			end

			alias_method :path_check, :quote_check

			alias_method :pass_check, :domain_name_check

			def api_version_check
				if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ self)
					raise <<~MSG
						api version is using an illegal form.
						Please use begin with letter and only use alphanumeric 
						for rest with a max length of 6
					MSG
				end
			end

			def pkg_version_check
				if ! (/^\d+\.\d+(?:\.\d+)?$/ =~ self)
					raise <<~MSG
						version is using an illegal form.
						Please use numbers seperated by dots
					MSG
				end
			end

			def env_prefix_check
				if ! (/^[a-zA-Z][a-zA-Z0-9]{,5}/ =~ self)
					raise "env prefix is using an illegal form. "
						"Please use begin with letter and only use alphanumeric "
						"for rest with a max length of 6"
				end
			end

			def db_name_check
				if ! (/^[a-zA-Z0-9_]{1,100}$/ =~ self)
					raise "db_name #{self} is using illegal characters"
					" or more than 100 characters"
				end
			end

		end


		refine Symbol do
			def instancify
				return self if start_with?("@") 
				"@#{to_s}".to_sym
			end
		end

	end

end