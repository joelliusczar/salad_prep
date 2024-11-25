module SaladPrep
	module Canary

		def self.version
			gemspec = File.absolute_path('../salad_prep.gemspec')
			Gem::Specification.load(gemspec).version
		end

		def self.fart_version
			puts("pphhttt #{version}")
		end

	end
end