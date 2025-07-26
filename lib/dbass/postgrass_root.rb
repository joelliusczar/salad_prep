#require 'pg'
require_relative "../extensions/string_ex"

module SaladPrep
	using StringEx

	class PostGrassRoot
		def initialize(egg)
			@egg = egg
			#@conn = connection
		end

		# def connection
		# 	PG.connect(user: "postgres")
		# end

		def self.create_db_user(username, pass, owner: false)
			username = username.dup
			pass = pass.dup

			username.db_name_check
			pass.pass_check

			create_db_flag = owner ? "CREATEDB" : ""

			script = <<~SQL
				sudo -u postgres psql -c \
				"CREATE USER #{username} WITH ENCRYPTED PASSWORD '#{pass}' #{create_db_flag}"
			SQL
			
			system(script)
		end

		def create_app_users
			db_pass = @egg.api_db_user_key
			raise "API: The system is not configured correctly" if db_pass.zero?
			PostGrassRoot.create_db_user(
				Enums::DbUsers::API_USER,
				db_pass
			)

			db_pass = @egg.janitor_db_user_key
			raise "Janitor: The system is not configured correctly" if db_pass.zero?
			PostGrassRoot.create_db_user(
				Enums::DbUsers::JANITOR_USER,
				db_pass
			)

		end

		def create_owner
			db_pass = @egg.db_owner_key
			raise "Owner: The system is not configured correctly" if db_pass.zero?
			PostGrassRoot.create_db_user(
				@egg.db_owner_name,
				db_pass
			)
		end

		def create_db(db_name)
			#copy first to prevent variable being swapped after validation.
			#though, this would only occur in multi thread situations
			db_name = db_name.dup 
			db_name.db_name_check
			db_owner_name = @egg.db_owner_name.dup
			db_owner_name.db_name_check
			

			script = <<~SQL
				sudo -u postgres psql -c \
				"CREATE DATABASE #{db_name} WITH OWNER = #{db_owner_name}"
			SQL
			
			system(script)
		end


	end
end