require "date"
require "fileutils"
require 'mysql'
require_relative "../arg_checker/arg_checker"
require_relative "./dbass"
require_relative "../box_box/enums"

module SaladPrep
	class MyAss < DbAss

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

		def backup_db
			FileUtils.mkdir_p(
				File.join(@egg.app_root, "db_backup")
			)
			timestamp = Time.new.strftime("%Y%m%d_%H%M")
			dest = File.join(
				@egg.app_root, "db_backup", "#{timestamp}_backup.sql"
			)
			system(
				"mysqldump",
				'-u',
				@egg.db_owner_name,
				"-p",
				@egg.db_owner_key,
				@egg.db_name,
				out: File.open(dest, "w"),
				exception: true
			)
			dest
		end

	end
end