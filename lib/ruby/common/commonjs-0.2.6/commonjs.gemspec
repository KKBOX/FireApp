# -*- encoding: utf-8 -*-
require File.expand_path('../lib/commonjs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Charles Lowell"]
  gem.email         = ["cowboyd@thefrontside.net"]
  gem.description   = "Host CommonJS JavaScript environments in Ruby"
  gem.summary       = "Provide access to your Ruby and Operating System runtime via the commonjs API"
  gem.homepage      = "http://github.com/cowboyd/commonjs.rb"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "commonjs"
  gem.require_paths = ["lib"]
  gem.version       = CommonJS::VERSION

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
end
