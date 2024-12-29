module SaladPrep
	module Instancifier

		def instancify_method
			@marked_inst = true
		end

		def singleton_method_added(name)
			if @marked_inst
				define_method(name) do |*args, **kwargs|
					self.class.send(name, *args, **kwargs)
				end
			end
			@marked_inst = false
		end

	end
end