module SaladPrep
	module Resorcerer

		ASSETS_DIR = "../../assets/"

		def self.resource_path(path)
			File.join(File.dirname(__FILE__), path)
		end

		def self.open_text(path)
			File.open(resource_path(path)).read
		end

		def self.bootstrap
			open_text("#{ASSETS_DIR}bootstrap")
		end

		def self.ruby_template
			open_text("#{ASSETS_DIR}ruby_template.rb")
		end

		def self.nginx_template
			open_text("#{ASSETS_DIR}nginx_template.conf")
		end

	end

end