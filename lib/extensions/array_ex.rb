module SaladPrep
	module ArrayEx
		refine Array do

			def le(other)
				(self <=> other) == -1
			end

			def ge(other)
				(self <=> other) > -1
			end
		end
	end
end