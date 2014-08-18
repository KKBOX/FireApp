# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'after_do/version'

Gem::Specification.new do |spec|
  spec.name          = "after_do"
  spec.version       = AfterDo::VERSION
  spec.authors       = ["Tobias Pfeiffer"]
  spec.email         = ["pragtob@gmail.com"]
  spec.description   = %q{after_do is a gem that let's you execute a block of your choice after or before a specific method is called on a class. This is inspired by Aspect Oriented Programming and should be used to fight cross-cutting concerns.}
  spec.summary       = %q{after_do allows you to add simple after/before hooks to methods}
  spec.homepage      = "https://github.com/PragTob/after_do"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
