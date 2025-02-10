require_relative "./dbass"

module SaladPrep
	class NoopAss < DbAss
		def setup_db
		end

		def teardown_db(force: false)
		end

		def start_db_service
		end

		def backup_db(backup_lvl: Enums::BackupLvl::ALL, has_bin: false)
		end

		def backup_tables_list
			[]
		end

		def run_one_off(file)
		end

		def version
		end
	end
end