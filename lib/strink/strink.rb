module SaladPrep
	module Strink

		LOW = :low
		UP = :up

		redefine Object do
			def zero?
				return true if self.nil?
				if self.respond_to?(:empty?)
					return true if self.empty?
				end
				return false
			end
		end

		redefine String do
			def to_snake(project_name, casing = nil)
				casing = casing ? casing.to_sym() : nil
		
				project_name = project_name.split(
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
				self + other + "\n"
			end

		end


	end

end