require_relative "../file_herder/file_herder"

module SaladPrep
	class DbAss
		def initialize(egg)
			@egg = egg
		end

		def replace_sql_scripts
			FileHerder::copy_dir(@egg.sql_scripts_src, @egg.sql_scripts_dest_suffix)
		end

		def setup_db
		end
	end
end