module SaladPrep
	module HashEx
		refine Hash do
		
			alias_method :__access__, :[]
	
			def coalesce(*keys)
				keys.each do |key|
					value = __access__(key)
					if ! value.nil?
						return value
					end
				end
				nil
			end
	
			def include?(*keys)
				keys.each { |key| return true if has_key(key) }
				false
			end
			
		end

	end
end