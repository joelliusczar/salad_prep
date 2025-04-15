Gem::Specification.new do |s|
	s.name = "salad_prep"
	s.version = "0.31.2"
	s.summary = "This is a shared repo between "
		"my apps to manage devops type of needs."
	s.authors = ["Joel Pridgen"]
	s.files = [
		"assets/bin_wrapper.rb",
		"assets/bootstrap_install",
		"assets/bundle_section.rb",
		"assets/nginx_evil.conf",
		"assets/nginx_template.conf",
		"lib/api_launcher/api_launcher.rb",
		"lib/api_launcher/py_api_launcher.rb",
		"lib/api_launcher/static_api_launcher.rb",
		"lib/arg_checker/arg_checker.rb",
		"lib/box_box/box_box.rb",
		"lib/box_box/enums.rb",
		"lib/canary/canary.rb",
		"lib/client_launcher/client_launcher.rb",
		"lib/client_launcher/node_client_launcher.rb",
		"lib/dbass/dbass.rb",
		"lib/dbass/enums.rb",
		"lib/dbass/myass_root.rb",
		"lib/dbass/myass.rb",
		"lib/dbass/noop_ass.rb",
		"lib/egg/egg.rb",
		"lib/extensions/hash_ex.rb",
		"lib/extensions/object_ex.rb",
		"lib/extensions/primitive_ex.rb",
		"lib/extensions/string_ex.rb",
		"lib/file_herder/file_herder.rb",
		"lib/installion/binstallion.rb",
		"lib/installion/installion.rb",
		"lib/instancifier/instancifier.rb",
		"lib/libby/libby.rb",
		"lib/libby/monty.rb",
		"lib/method_marker/method_marker.rb",
		"lib/remote/enums.rb",
		"lib/remote/remote.rb",
		"lib/resorcerer/resorcerer.rb",
		"lib/salad_prep.rb",
		"lib/test_honcho/test_honcho.rb",
		"lib/test_honcho/py_test_honcho.rb",
		"lib/toob/toob.rb",
		"lib/w_spoon/cert_info.rb",
		"lib/w_spoon/w_spoon.rb"
	]
	s.homepage = "https://github.com/joelliusczar/salad_prep"
	s.required_ruby_version = ">= 3.3.5"
	s.license = "MIT"
	s.add_dependency "base64", "~> 0.2"
	s.add_dependency "ostruct", "~> 0.6" #this must be used internally?
	s.add_dependency "ruby-mysql", "~> 4.1"
	s.add_dependency "bigdecimal", "~> 3.1"
	s.metadata = { 
		"source_code_uri" => "https://github.com/joelliusczar/salad_prep"
	}
end
