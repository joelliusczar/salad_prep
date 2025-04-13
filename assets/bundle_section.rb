require 'bundler/inline'
require 'bundler'

cmd = ARGV[0]

if ARGV.empty? && defined?(show_commands)
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
		args_hash[idx.to_s] = arg
		args_hash[arg] = "true"
		idx += 1
	end
end
ARGV.clear

if cmd == "spit_procs"
	args_hash["--local"] = "true"
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