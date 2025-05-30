require 'mysql'
require_relative "../arg_checker/arg_checker"
require_relative "./enums"
require_relative "../extensions/string_ex"

module SaladPrep
	using StringEx

	class MyAssRoot

		def initialize(egg, pass)
			@egg = egg
			@conn = connection(pass)
		end

		def connection(pass)
			Mysql.connect("mysql://root:#{pass}@127.0.0.1")
		end

		def create_db(db_name)
			#copy first to prevent variable being swapped after validation.
			#though, this would only occur in multi thread situations
			db_name = db_name.dup 
			db_name.db_name_check
			@conn.query("CREATE DATABASE IF NOT EXISTS #{db_name}")
		end

		def create_db_user(username, host, pass)
			username = username.dup
			host = host.dup
			username.db_name_check
			host.db_name_check
			script = <<~SQL
				CREATE USER IF NOT EXISTS `#{username}`@`#{host}` 
				IDENTIFIED BY ?
			SQL
			stmt = @conn.prepare(script)
			stmt.execute(pass)
		end

		def create_app_users
			db_pass = @egg.api_db_user_key
			raise "API: The system is not configured correctly" if db_pass.zero?
			create_db_user(
				Enums::DbUsers::API_USER,
				"localhost",
				db_pass
			)

			db_pass = @egg.janitor_db_user_key
			raise "Janitor: The system is not configured correctly" if db_pass.zero?
			create_db_user(
				Enums::DbUsers::JANITOR_USER,
				"localhost",
				db_pass
			)

		end

		def create_owner
			db_pass = @egg.db_owner_key
			raise "Owner: The system is not configured correctly" if db_pass.zero?
			create_db_user(
				@egg.db_owner_name,
				"localhost",
				db_pass
			)
		end

		def grant_owner_roles(db_name)
			db_name = db_name.dup
			owner_name = @egg.db_owner_name.dup
			db_name.db_name_check
			owner_name.db_name_check
			grants = <<~SQL
				GRANT ALL PRIVILEGES ON #{db_name}.* to
				#{owner_name} WITH GRANT OPTION
			SQL
			@conn.query(grants)
			@conn.query("GRANT RELOAD ON *.* to #{owner_name}")
			@conn.query("FLUSH PRIVILEGES")
		end

		def drop_database(db_name)
			db_name = db_name.dup
			db_name.db_name_check
			unless db_name.start_with("test_")
				raise "only test databases can be removed" 
			end
			@conn.query("DROP DATABASE IF EXISTS #{db_name}")
		end

		def self.is_root_pass_set?
			! system(
				"mysql -u root -e 'SHOW DATABASES';",
				out: File::NULL, 
				err: File::NULL
			)
		end

		def self.revoke_default_db_accounts
			script = <<~SQL
				mysql -u root -e \
				"REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'mysql'@'localhost';"
			SQL
			system(script, exception: true)
		end

		def self.set_db_root_initial_password(pass)
			pass = pass.dup
			pass.quote_check
			script = <<~SQL
				mysql -u root -e \
				"SET PASSWORD FOR root@localhost = PASSWORD('#{pass}');"
			SQL
			system(script, exception: true)
		end


	end
end