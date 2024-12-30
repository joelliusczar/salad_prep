require "set"

module SaladPrep
	module MethodMarker
		@current_attrs = []
		@attr_method_hash = {}
		@method_attr_hash = {}

		def self.extended(other)
			other.class_eval do
				def marked_methods(*attrs)
					self.class.marked_methods(*attrs)
				end

				def method_attrs(name)
					self.class.method_attrs(name)
				end
			end
		end

		def link_method_attrs(name, attrs)
			@method_attr_hash = {} if @method_attr_hash.nil?
			@attr_method_hash = {} if @attr_method_hash.nil?
			attr_hash = @method_attr_hash[name] || {}
			attrs.each do |attr|
				if attr.kind_of?(Hash)
					attr.each_pair do |k, v|
						attr_hash[k] = v
						method_list = @attr_method_hash[k] || Set.new
						method_list.add(name)
						@attr_method_hash[k] = method_list
					end
				else
					method_list = @attr_method_hash[attr] || Set.new
					method_list.add(name)
					attr_hash[attr] = nil
					@attr_method_hash[attr] = method_list
				end
			end
			@method_attr_hash[name] = attr_hash
		end

		def late_mark_for(name, *attrs, **kwattrs)
			link_method_attrs(name, attrs.push(kwattrs))
		end
		
		def register_method(name)
			@current_attrs = [] if @current_attrs.nil?
			link_method_attrs(name, @current_attrs)
			@current_attrs.clear
		end

		def method_added(name)
			super
			register_method(name)
		end

		unbound_register = instance_method(:register_method)
		unbound_register.bind(self)
		def singleton_method_added(name)
			super
			register_method(name)
		end

		def mark_for(*attrs, **kwargs)
			@current_attrs = [] if @current_attrs.nil?
			@current_attrs.push(*attrs, :__implied__, kwargs)
		end

		def marked_methods(*attrs)
			@attr_method_hash = {} if @attr_method_hash.nil?
			result = attrs.reduce(@attr_method_hash[:__implied__] || Set.new) do |a, c|
				a &= (@attr_method_hash[c] || Set.new)
			end
			if superclass.respond_to?(:marked_methods)
				result |= superclass.marked_methods(*attrs)
			end
			result.to_a
		end

		def method_attrs(name)
			result = @method_attr_hash[name] || {}
			if superclass.respond_to?(:method_attrs)
				return result.merge(superclass.method_attrs(name))
			end
			result
		end
		
	end
end