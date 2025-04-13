module SaladPrep
	module PrimitiveEx
		refine Integer do

			def zero?
				return self == 0
			end

			def populated?
				! zero?
			end

		end

		refine TrueClass do

			def zero?
				false
			end
			
			def populated?
				self
			end

		end

		refine FalseClass do
		
			def zero?
				true
			end
			
			def populated?
				self
			end

		end


	end
end