require 'java'
require 'bundler/setup'
Bundler::GemHelper.install_tasks

desc "remove all build artifacts"
task :clean do
  sh "rm -rf pkg/"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new
