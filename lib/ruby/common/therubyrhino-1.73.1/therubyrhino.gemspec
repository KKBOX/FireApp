# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rhino/version"

Gem::Specification.new do |s|
  s.name = %q{therubyrhino}
  s.version = Rhino::VERSION
  s.authors = ["Charles Lowell"]
  s.description = %q{Call javascript code and manipulate javascript objects from ruby. Call ruby code and manipulate ruby objects from javascript.}
  s.email = %q{cowboyd@thefrontside.net}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/cowboyd/therubyrhino}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{therubyrhino}
  s.summary = %q{Embed the Rhino JavaScript interpreter into JRuby}

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "jruby-openssl"
end
