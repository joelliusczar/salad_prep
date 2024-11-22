require "salad_prep"

class RemoteEgg < {parent_egg}

	def server_env_check_recommended
		super
		{server_env_check_recommended_body}
	end

	def server_env_check_required
		super
		{server_env_check_required_body}
	end

end