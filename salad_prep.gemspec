Gem::Specification.new do |s|
	s.name = "salad_prep"
	s.version = "0.1.10"
	s.summary = "This is a shared repo between "
		"my apps to manage devops type of needs."
	s.authors = ["Joel Pridgen"]
	s.files = [
		"assets/bootstrap",
		"lib/box_box/box_box.rb",
		"lib/brick_stack/brick_stack.rb",
		"lib/dbass/dbass.rb",
		"lib/egg/egg.rb",
		"lib/file_herder/file_herder.rb",
		"lib/remote/remote.rb",
		"lib/resorcerer/resorcerer.rb",
		"lib/salad_prep.rb",
		"lib/strink/strink.rb",
		"lib/test_honcho/test_honcho.rb"
	]
	s.homepage = "https://github.com/joelliusczar/salad_prep"
	required_ruby_version = ">= 3.3.0"
end