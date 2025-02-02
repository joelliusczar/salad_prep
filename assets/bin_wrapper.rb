#!/usr/bin/env ruby

<= bundle_section %>

require "salad_prep"
require_relative "./provincial"

using SaladPrep::StringEx
using SaladPrep::HashEx

Provincial::Toob.set_all(Provincial.egg.env_prefix)

@actions_hash = {}

<%= actions_body %>

def show_commands
	puts("any of the following are valid commands")
	puts("-V : Prints the salad prep version")
	@actions_hash.keys.sort.each do |key|
		puts(key)
	end
end

def bin_action_wrap(args_hash)
	if args_hash.include?("-testing")
		Provincial.egg.run_test_block do
			yield
		end
	else
		yield
	end
end

def root_script_pre(ruby_version)
	env_prefix = Provincial.egg.env_prefix
	app_home_var = "#{env_prefix}_APP_ROOT"
	root_script = 'export ASDF_DIR="$HOME/.asdf"'
	root_script ^= "export #{env_prefix}_ENV='local'"
	root_script ^= '. "$HOME/.asdf/asdf.sh"'
	root_script ^= Provincial.egg.env_exports(prefer_keys_file: false)
	root_script ^= "export #{app_home_var}='#{Provincial.egg.app_root}'"
	root_script ^= "asdf shell ruby #{ruby_version}"
end

def bundle_section(args_hash)
	prefer_local = ! args_hash["-local"].nil?prefer_local = ! args_hash["-local"].nil?
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

def wrap_ruby(content, args_hash, redirect_outs: true)
	
	body = <<~PRE
		ruby <<'EOF'

		#{bundle_section(args_hash)}
		require "tempfile"
		#{Provincial.egg.app_lvl_definitions_script}
		Provincial.egg.load_env
		Process::Sys.setegid(Provincial::BoxBox.login_group_id)
		Process::Sys.seteuid(Provincial::BoxBox.login_id)
		if ! ENV["LOGIN_HOME"].nil? && ENV["LOGIN_HOME"].length > 0
			ENV["HOME"] = ENV["LOGIN_HOME"]
		end
		if ! ENV["PATH_ADDS"].nil? && ENV["PATH_ADDS"].length > 0
			ENV["PATH"] = "\#{ENV['PATH']}:\#{ENV['PATH_ADDS']}"
		end
		<%% if redirect_outs %>
		Tempfile.create do |tmp|
			Provincial::Toob.register_sub(tmp) do
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

if cmd == "-V"
	puts(SaladPrep::Canary.version)
elsif cmd == "-h"
	show_commands
else
	@actions_hash[cmd].call(args_hash)
end



