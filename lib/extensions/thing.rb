module SaladPrep
	module Thing

		refine Object do
			def embodied?
				! nil?
			end
		end

	end
end