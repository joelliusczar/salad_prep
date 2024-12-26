#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
	source "https://rubygems.org"

	gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
end

require "salad_prep"
require_relative "./provincial"

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
	if args_hash.include?("testing")
		Provincial.egg.run_test_block do
			yield
		end
	else
		yield
	end
end

if ARGV.empty?
	show_commands
	exit
end

args_hash = {}
cmd = ARGV[0]
ARGV.drop(1).each_with_index do |arg, idx|
	if arg.include?("=")
		split = arg.split("=")
		args_hash[split[0].strip] = split[1].strip
	else
		args_hash[idx] = arg
	end
end
ARGV.clear

Provincial.log = Provincial.egg.log_dest

if cmd == "-V"
	puts(SaladPrep::Canary.version)
elsif cmd == "-h"
	show_commands
else
	@actions_hash[cmd].call(args_hash)
end



