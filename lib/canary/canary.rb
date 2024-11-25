module SaladPrep
	module Canary

		def self.version
			gemspec = File.expand_path("../../../salad_prep.gemspec",__FILE__)
			Gem::Specification.load(gemspec).version
		end

		def self.fart_version
			puts("pphhttt #{version}")
		end

	end
end