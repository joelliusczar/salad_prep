require_relative "../dbass/enums"
require_relative "../file_herder/file_herder"
require_relative "../toob/toob"

module SaladPrep
	class DbAss

		def initialize(egg)
			@egg = egg
		end

		def replace_sql_scripts
			FileHerder::copy_dir(@egg.sql_scripts_src, @egg.sql_scripts_dest)
		end

		def setup_db
			raise "teardown_db not implemented"
		end

		def teardown_db(force: false)
			raise "teardown_db not implemented"
		end

		def start_db_service
			raise "start_db_service not implemented"
		end

		def backup_db(backup_lvl: Enums::BackupLvl::ALL, has_bin: false)
			raise "backup_db not implemented"
		end

		def backup_tables_list
			[]
		end

		def run_one_off(file)
			raise "run_one_off not implemented"
		end

		def version
			raise "version not implemented"
		end

	end
end