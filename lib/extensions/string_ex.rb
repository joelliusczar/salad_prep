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
				if is_kind_of?(String)
					downcase == "true"
				else
					false
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
				sub("~", ENV["HOME"]) if start_with?("~")
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