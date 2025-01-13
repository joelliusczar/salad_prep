require "date"
require "fileutils"
require 'mysql'
require_relative "../arg_checker/arg_checker"
require_relative "../box_box/enums"
require_relative "./dbass"
require_relative "./enums"
require_relative "../extensions/array_ex"
require_relative "../extensions/string_ex"

module SaladPrep
	class MyAss < DbAss
		using ArrayEx
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
			Toob.diag&.puts("owner name: #{owner_name}")
			Toob.diag&.puts(
				"owner key?  #{owner_key.populated? ? 'Yes' : 'No'}"
			)
			Toob.diag&.puts("db_name: #{db_name}")

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

		def is_dump_broken
			installed_version = version
			minor = installed_version[1]
			patch = installed_version[2]
			if installed_version[0] < 10
				return true
			end
			if installed_version[0] == 10
				if installed_version.le([10,5,25])
					return true
				end
				if minor == 6 && patch < 18
					return true
				end
				if minor == 11 && patch < 8
					return true
				end
			end
			if installed_version[0] == 11
				if installed_version.le([11,0,6])
					return true
				end
				if minor == 1 && patch < 5
					return true
				end
				if minor == 2 && patch < 4
					return true
				end
				if minor == 4 && patch < 2
					return true
				end
			end
			false
		end

		def run_one_off(file)
			IO.pipe do |r, w|
				Thread.new do
					until (line = file.gets).nil?
						sandbox = "/*!999999\\- enable the sandbox mode */"
						if is_dump_broken && line.include?(sandbox)
							next
						end
						w.write(line)
					end
					w.close
				end
				owner_key = @egg.db_owner_key(prefer_keys_file: false)
				system(
					"mysql",
					"-u",
					@egg.db_owner_name,
					"-p#{owner_key}",
					@egg.db_name,
					in: r
				)
			end
		end

		def version
			owner_key = @egg.db_owner_key(prefer_keys_file: false)
			version_str = BoxBox.run_and_get(
				"mysql",
				"-u",
				@egg.db_owner_name,
				"-p#{owner_key}",
				in_s: "SELECT version()",
				exception: true
			)
			version_str.match(/(\d+)\.(\d+)\.(\d+)/).to_a.drop(1).map(&:to_i)
		end

	end
end