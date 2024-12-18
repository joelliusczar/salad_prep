require "erb"

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

		def self.bootstrap_compile(update_salad_prep: false)
			template = ERB.new(bootstrap, trim_mode:"<>")
			template.result_with_hash({
				update_salad_prep: update_salad_prep ? "true" : ""
			})
		end

		def self.nginx_template
			open_text("#{ASSETS_DIR}nginx_template.conf")
		end

		def self.nginx_evil_conf
			open_text("#{ASSETS_DIR}nginx_evil.conf")
		end

		def self.bin_wrapper_template
			open_text("#{ASSETS_DIR}bin_wrapper.rb")
		end

		def self.bin_wrapper_template_compile(action_body)
			template = ERB.new(bin_wrapper_template, trim_mode:"<>")
			template.result_with_hash({
				actions_body: actions_body
			})
		end

	end

end