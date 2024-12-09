#!/usr/bin/env ruby

require "salad_prep"
<%= context_body %>

def action(args_hash)
	<%= action_body %>
end

next_action = lambda do |args_hash| 
	action(args_hash)
end

args_hash = {}
ARGV.each do |arg|
	if arg == "-V"
		next_action = ->(_) { puts(SaladPrep::Canary.version) }
	else
		if arg.include?("=")
			split = arg.split("=")
			args_hash[split[0].trim] = split[1].trim
		else
			args_hash[arg] = true
		end
	end
end
ARGV.clear



next_action.call(args_hash)
