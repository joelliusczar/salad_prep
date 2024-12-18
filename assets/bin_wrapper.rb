#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
	source "https://rubygems.org"

	gem "salad_prep", git: "https://github.com/joelliusczar/salad_prep"
end

require "salad_prep"
require_relative "./provincial"

actions_hash = {}

<%= actions_body %>

args_hash = {}
cmd = ARGV[0]
ARGV.drop(1).each do |arg|
	if arg.include?("=")
		split = arg.split("=")
		args_hash[split[0].trim] = split[1].trim
	else
		args_hash[arg] = true
	end
end
ARGV.clear
if cmd == "-V"
	puts(SaladPrep::Canary.version)
else
	actions_hash[cmd].call(args_hash)
end



