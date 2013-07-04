# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "less/version"

Gem::Specification.new do |s|
  s.name        = "less"
  s.version     = Less::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Charles Lowell"]
  s.email       = ["cowboyd@thefrontside.net"]
  s.homepage    = "http://lesscss.org"
  s.summary     = %q{Leaner CSS, in your browser or Ruby (via less.js)}
  s.description = %q{Invoke the Less CSS compiler from Ruby}

  s.rubyforge_project = "less"

  s.files         = `git ls-files`.split("\n")
  Dir.chdir('lib/less/js') do
    s.files += `git ls-files`.split("\n").map {|f| File.join('lib/less/js',f)}
  end
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "commonjs", "~> 0.2.6"
end
