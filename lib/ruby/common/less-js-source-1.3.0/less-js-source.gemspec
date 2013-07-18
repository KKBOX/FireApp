# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "less-js-source"
  s.version     = '1.3.0'
  s.authors     = ["Alexis Sellier"]
  s.email       = ["alexis@cloudhead.io"]
  s.homepage    = "http://lesscss.org"
  s.summary     = %q{Leaner CSS, in your browser.}
  s.description = %q{Leaner CSS, in your browser.}

  s.rubyforge_project = "less-js-source"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
