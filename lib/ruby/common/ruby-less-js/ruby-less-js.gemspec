# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "less-js"
  s.version     = '0.1.1'

  s.authors     = ["Joshua Peek", "Adnan Ali"]
  s.email       = ["josh@joshpeek.com", "adnan.ali@gmail.com"]
  s.homepage    = "https://github.com/thisduck/ruby-less-js"
	s.summary     = "Ruby Less.js Compiler"
	s.description = <<-EOS
		Ruby Less.js is a bridge to the JS Less.js compiler.
	EOS


  s.rubyforge_project = "less-js"

	s.add_dependency 'less-js-source'
	s.add_dependency 'execjs'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
