module SaladPrep
	module Strink

		LOW = :low
		UP = :up

		def self.empty_s? (s)
			!s || s.empty?
		end

		def self.to_snake(project_name, casing = nil)
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

	end

end