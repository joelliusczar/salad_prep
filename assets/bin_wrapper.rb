#!/usr/bin/env ruby

require 'bundler/inline'
require 'bundler'

cmd = ARGV[0]

if ARGV.empty?
	show_commands
	exit
end

args_hash = {}
idx = 0
ARGV.drop(1).each do |arg| #drop 0 since that's the command itself
	if arg.include?("=")
		split = arg.split("=")
		args_hash[split[0].strip.downcase] = split[1].strip
	else
		args_hash[idx] = arg
		args_hash[arg] = true
		idx += 1
	end
end
ARGV.clear

if cmd == "spit_procs"
	args_hash["-local"] = true
end


gemfile do
	source "https://rubygems.org"

	prefer_local = ! args_hash["-local"].nil?
	if ! prefer_local || cmd == "refresh_bins"
		gem(
			"salad_prep",
			git: "https://github.com/joelliusczar/salad_prep"
		)
	else
		git_hash = `git ls-remote https://github.com/joelliusczar/salad_prep.git`
			.split.first[0,12]
		gem(
			"salad_prep",
			path: "#{Bundler.bundle_path.to_path}/bundler/gems/salad_prep-#{git_hash}"
		)
	end
end

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

if cmd == "-V"
	puts(SaladPrep::Canary.version)
elsif cmd == "-h"
	show_commands
else
	@actions_hash[cmd].call(args_hash)
end



