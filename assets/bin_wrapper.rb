#!/usr/bin/env ruby

<%= bundle_section %>

require "salad_prep"
using SaladPrep::StringEx
using SaladPrep::HashEx
using SaladPrep::PrimitiveEx


def bundle_section
	prefer_local = ! @args_hash["-local"].nil?
	bundle = <<~BUNDLE
		require 'bundler/inline'
		require 'bundler'

		gemfile do
			source "https://rubygems.org"

			prefer_local = #{prefer_local ? "true": "false"}
			if ! prefer_local
				gem(
					"salad_prep",
					git: "https://github.com/joelliusczar/salad_prep"
				)
			else
				git_hash = `git ls-remote https://github.com/joelliusczar/salad_prep.git`
					.split.first[0,12]
				gem(
					"salad_prep",
					path: "\#{Bundler.bundle_path.to_path}/bundler/gems/salad_prep-\#{git_hash}"
				)
			end
		end

		require "salad_prep"
	BUNDLE
end

@actions_hash = {}

def show_commands
	puts("any of the following are valid commands")
	puts("-V : Prints the salad prep version")
	@actions_hash.keys.sort.each do |key|
		puts(key)
	end
end


begin

require_relative "./provincial"


Provincial::Toob.set_all(Provincial.egg.env_prefix)


def bin_action_wrap()
	Provincial::Toob.diag&.puts(@args_hash)
	if @args_hash.include?("-testing")
		Provincial.egg.run_test_block do
			yield
		end
	else
		yield
	end
end



<%= actions_body %>



def root_script_pre(ruby_version)
	env_prefix = Provincial.egg.env_prefix
	env_name = Provincial.egg.current_env
	app_home_var = "#{env_prefix}_APP_ROOT"
	root_script = 'export ASDF_DIR="$HOME/.asdf"'
	root_script ^= "export #{env_prefix}_ENV='#{env_name}'"
	root_script ^= '. "$HOME/.asdf/asdf.sh"'
	root_script ^= Provincial.egg.env_exports(prefer_keys_file: false)
	root_script ^= "export #{app_home_var}='#{Provincial.egg.app_root}'"
	root_script ^= "asdf shell ruby #{ruby_version}"
end

def get_current_branch
	Dir.chdir(Provincial.egg.local_repo_path) do 
		`git branch --show-current 2>/dev/null`.strip
	end
end


def wrap_ruby(content, redirect_outs: true)
	
	body = <<~PRE
		ruby <<'EOF'

		args_hash = {
			<%% @args_hash.each do |k,v| %>
				"<%%=k.is_a?(String) ? k.gsub('"','\"') : k %>" =>
					"<%%=v.is_a?(String) ? v.gsub('"','\"') : v %>",
			<%% end %>
		}

		#{bundle_section}
		require "tempfile"
		#{Provincial.egg.app_lvl_definitions_script}
		Provincial.egg.load_env
		Process::Sys.setegid(Provincial::BoxBox.login_group_id)
		Process::Sys.seteuid(Provincial::BoxBox.login_id)

		<%% if redirect_outs %>
		
		File.open("supressed_output", "a") do |file|
			Provincial::Toob.register_sub(file) do
				<%% content.split("\n").each do |l| %>
				<%%= l %>

				<%% end %>
			end

		end
		<%% else %>
		<%% content.split("\n").each do |l| %>
		<%%= l %>

		<%% end %>
		<%% end %>
		EOF
	PRE
	ERB.new(body, trim_mode:">").result(binding)
end

rescue => e


	#backup refresh_procs
	@actions_hash["refresh_procs"] = proc do
		SaladPrep::Binstallion.install_bins(
			"<%= backup_env_prefix %>",
			"<%= backup_src %>",
			"<%= backup_dest %>",
			""
		)
		puts("#{SaladPrep::Canary.version}")
	end

	$stderr.puts("Error while trying to create bin file.")
	$stderr.puts(e.backtrace * "\n")
	$stderr.puts(e.message)
end

if cmd == "-V"
	puts(SaladPrep::Canary.version)
elsif cmd == "-h"
	show_commands
else
	instance_eval(&@actions_hash[cmd])
end



