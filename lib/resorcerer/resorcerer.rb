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

		def self.ruby_template
			open_text("#{ASSETS_DIR}ruby_template.rb")
		end

		def self.ruby_template_compile(setup_lvl:, current_branch: "main")
			template = ERB.new(ruby_template, trim_mode:"<>")
			template.result_with_hash({
				setup_lvl: setup_lvl,
				current_branch: current_branch
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

		def self.bin_wrapper_template_compile(context_body, action_body)
			template = ERB.new(bin_wrapper_template, trim_mode:"<>")
			template.result_with_hash({
				context_body: context_body,
				action_body: action_body
			})
		end

	end

end