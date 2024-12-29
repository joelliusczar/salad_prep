module SaladPrep
	module Canary

		def self.loaded_gemspec
			gemspec = File.expand_path("../../../.gemspec",__FILE__)
			Gem::Specification.load(gemspec)
		end

		def self.version
			loaded_gemspec.version
		end

		def self.fart_version
			puts("pphhttt #{version}")
		end

		def self.source_code_uri
			loaded_gemspec.metadata["source_code_uri"]
		end

	end
end