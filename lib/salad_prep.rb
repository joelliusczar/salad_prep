require_relative "api_launcher/api_launcher"
require_relative "api_launcher/py_api_launcher"
require_relative "api_launcher/static_api_launcher"
require_relative "arg_checker/arg_checker"
require_relative "box_box/box_box"
require_relative "box_box/enums"
require_relative "canary/canary"
require_relative "client_launcher/client_launcher"
require_relative "client_launcher/node_client_launcher"
require_relative "dbass/dbass"
require_relative "dbass/enums"
require_relative "dbass/myass"
require_relative "dbass/myass_root"
require_relative "dbass/noop_ass"
require_relative "egg/egg"
require_relative "extensions/hash_ex"
require_relative "extensions/object_ex"
require_relative "extensions/primitive_ex"
require_relative "extensions/string_ex"
require_relative "file_herder/file_herder"
require_relative "installion/binstallion"
require_relative "installion/installion"
require_relative "instancifier/instancifier"
require_relative "libby/monty"
require_relative "libby/libby"
require_relative "method_marker/method_marker"
require_relative "resorcerer/resorcerer"
require_relative "remote/enums"
require_relative "remote/remote"
require_relative "test_honcho/test_honcho"
require_relative "test_honcho/py_test_honcho"
require_relative "toob/toob"
require_relative "w_spoon/cert_info"
require_relative "w_spoon/w_spoon"

#this is needed because I was running into a bizare case
#where Digest::SHA256 would cause a load error
#minimal code to duplicate issue
# require "tempfile"

# sub = <<~SUB
# 	export ASDF_DIR="$HOME/.asdf"
# 	. "$HOME/.asdf/asdf.sh"
# 	asdf shell ruby 3.3.5
# 	ruby <<EOF
# 		require 'bundler'
# 		require 'bundler/inline'
# 		gemfile do
# 				source "https://rubygems.org"
# 				gem 'digest', require: 'digest/sha2'
# 		end	

# 		require "digest"
# 		# p Digest::SHA256
# 		Process::Sys.seteuid(1000)
# 		p Digest::SHA256
# 		puts("howdy")
# 	EOF
# SUB
# #p Digest::SHA256
#system("sudo", "sh", "-c", sub)
require "digest"
Digest::SHA256