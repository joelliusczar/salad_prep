require_relative "../dbass/enums"
require_relative "../file_herder/file_herder"
require_relative "../loggable/loggable"

module SaladPrep
	class DbAss
		include Loggable

		def initialize(egg)
			@egg = egg
		end

		def replace_sql_scripts
			FileHerder::copy_dir(@egg.sql_scripts_src, @egg.sql_scripts_dest)
		end

		def setup_db
			raise "teardown_db not implemented"
		end

		def teardown_db
			raise "teardown_db not implemented"
		end

		def start_db_service
			raise "start_db_service not implemented"
		end

		def backup_db(backup_lvl: BackupLvl.ALL)
			raise "backup_db not implemented"
		end

	end
end