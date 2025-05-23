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

		def self.bootstrap_install_template
			open_text("#{ASSETS_DIR}bootstrap_install")
		end

		def self.bootstrap_install(root: false)
			template = ERB.new(bootstrap_install_template, trim_mode:"<>")
			template.result_with_hash({
				root: root
			})
		end

		def self.nginx_template
			open_text("#{ASSETS_DIR}nginx_template.conf")
		end

		def self.nginx_evil_conf
			open_text("#{ASSETS_DIR}nginx_evil.conf")
		end

		def self.bundle_section_path
			File.absolute_path("#{ASSETS_DIR}bundle_section.rb")
		end

		def self.bundle_section
			open_text("#{ASSETS_DIR}bundle_section.rb")
		end

		def self.bin_wrapper_template
			open_text("#{ASSETS_DIR}bin_wrapper.rb")
		end

		def self.bin_wrapper_template_compile(
			actions_body,
			backup_env_prefix,
			backup_src,
			backup_dest
		)
			
			template = ERB.new(bin_wrapper_template, trim_mode:"<>")
			template.result_with_hash({
				actions_body: actions_body,
				bundle_section: bundle_section,
				backup_src: backup_src,
				backup_dest: backup_dest,
				backup_env_prefix: backup_env_prefix,
			})
		end

	end

end