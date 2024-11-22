require_relative "./egg"

module SaladPrep
	class PyEgg

		def initialize(
			py_env:
			**rest
		)
			super(**rest)
			@py_env = py_env
		end

	end
end