require 'bundler'
require 'bundler/setup'
require "rspec/core/rake_task"

Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

