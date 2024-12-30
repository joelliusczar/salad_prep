module SaladPrep
	module ObjectEx

		refine Object do
			def embodied?
				! nil?
			end
		end

	end
end