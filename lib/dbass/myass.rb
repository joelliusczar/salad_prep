require "date"
require "fileutils"
require 'mysql'
require_relative "../arg_checker/arg_checker"
require_relative "../box_box/enums"
require_relative "./dbass"
require_relative "./enums"
require_relative "../extensions/string_ex"

module SaladPrep
	class MyAss < DbAss
		using StringEx

		def connection(user, pw, db)
			Mysql.connect("mysql://#{user}:#{pw}@127.0.0.1/#{db}")
		end

		def start_db_service
			case Gem::Platform::local.os
			when Enums::BoxOSes::MACOS
				system("brew services start mariadb", exception: true)
			when Enums::BoxOSes::LINUX
				BoxBox.restart_service("mariadb")
			else
				raise "Restarting server not configured for #{Gem::Platform::local.os}"
			end
		end

		def backup_db(backup_lvl: Enums::BackupLvl::ALL, has_bin: false)
			FileUtils.mkdir_p(
				File.join(@egg.app_root, "db_backup")
			)
			timestamp = Time.new.strftime("%Y%m%d_%H%M")
			dest = File.join(
				@egg.app_root, "db_backup", "#{timestamp}_backup"
			)
			owner_name = @egg.db_owner_name
			owner_key = @egg.db_owner_key(prefer_keys_file: false)
			db_name = @egg.db_name
			diag_log&.puts("owner name: #{owner_name}")
			diag_log&.puts("owner key?  #{owner_key.populated? ? 'Yes' : 'No'}")
			diag_log&.puts("db_name: #{db_name}")

			cmd_arr = [
				"mysqldump",
				'-u',
				owner_name,
				"-p#{owner_key}",
				db_name,
			]

			if backup_lvl&.downcase == Enums::BackupLvl::STRUCTURE
				cmd_arr.push("--no-data")
				dest += "_STRUCTURE.sql"
			elsif backup_lvl&.downcase == Enums::BackupLvl::DATA
				cmd_arr.push("--no-create-info")
				dest += "_DATA.sql"
			elsif backup_lvl&.downcase == Enums::BackupLvl::SELECT
				cmd_arr.push("--no-create-info")
				cmd_arr.push(*backup_tables_list)
				dest += "_SELECT.sql"
			else
				dest += "_ALL.sql"
			end

			cmd_arr.push("--hex-blob") if has_bin

			
			system(
				*cmd_arr,
				out: File.open(dest, "w"),
				exception: true
			)
			dest
		end

		def run_one_off(file)
			system(
				"mysql",
				"-u",
				@egg.db_owner_name,
				"-p",
				@egg.db_owner_key,
				@egg.db_name,
				in: file
			)
		end

	end
end