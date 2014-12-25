#-*- mode: ruby -*-

require 'maven/ruby/tasks'

# the actual build configuration is inside the Mavenfile

task :default => :build

Rake::Task[:jar].clear
desc "Package jopenssl.jar with the compiled classes"
task :jar => :maven do
  maven.prepare_package '-Dmaven.test.skip'
end

namespace :jar do
  desc "Package jopenssl.jar file (and dependendent jars)"
  task :all => :maven do
    maven.package '-Dmaven.test.skip'
  end
end