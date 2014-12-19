# -*- ruby encoding: utf-8 -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :doofus
Hoe.plugin :gemspec2
Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :travis
Hoe.plugin :email unless ENV['CI'] or ENV['TRAVIS']

spec = Hoe.spec 'mime-types' do
  developer('Austin Ziegler', 'halostatue@gmail.com')
  self.need_tar = true

  self.require_ruby_version '>= 1.9.2'

  self.history_file = 'History.rdoc'
  self.readme_file = 'README.rdoc'
  self.extra_rdoc_files = FileList["*.rdoc"].to_a
  self.licenses = ["MIT", "Artistic 2.0", "GPL-2"]

  self.extra_dev_deps << ['hoe-doofus', '~> 1.0']
  self.extra_dev_deps << ['hoe-gemspec2', '~> 1.1']
  self.extra_dev_deps << ['hoe-git', '~> 1.6']
  self.extra_dev_deps << ['hoe-rubygems', '~> 1.0']
  self.extra_dev_deps << ['hoe-travis', '~> 1.2']
  self.extra_dev_deps << ['minitest', '~> 5.3']
  self.extra_dev_deps << ['rake', '~> 10.0']
  self.extra_dev_deps << ['simplecov', '~> 0.7']
  self.extra_dev_deps << ['coveralls', '~> 0.7']
end

task :support do
  %w(lib support).each { |path|
    $LOAD_PATH.unshift(File.join(Rake.application.original_dir, path))
  }
end

task 'support:nokogiri' => :support do
  begin
    gem 'nokogiri'
  rescue Gem::LoadError
    fail "Nokogiri is not installed. Please install it."
  end
end

namespace :benchmark do
  desc 'Benchmark Load Times'
  task :load, [ :repeats ] => :support do |t, args|
    require 'benchmarks/load'
    Benchmarks::Load.report(File.join(Rake.application.original_dir, 'lib'),
                            args.repeats)
  end

  desc 'Show object counts'
  task objects: :support do
    GC.start
    objects_before = ObjectSpace.count_objects

    require "mime/types"
    GC.start
    objects_after = ObjectSpace.count_objects
    objects_before.keys.grep(/T_/).map { |key|
      [ key, objects_after[key] - objects_before[key] ]
    }.sort_by { |key, delta| -delta }.each { |key, delta|
      puts "%10s +%6d" % [ key, delta ]
    }
  end
end

namespace :test do
  task :coveralls do
    spec.test_prelude = [
      'require "psych"',
      'require "simplecov"',
      'require "coveralls"',
      'SimpleCov.formatter = Coveralls::SimpleCov::Formatter',
      'SimpleCov.start("test_frameworks") { command_name "Minitest" }',
      'gem "minitest"'
    ].join('; ')
    Rake::Task['test'].execute
  end

  desc 'Run test coverage'
  task :coverage do
    spec.test_prelude = [
      'require "simplecov"',
      'SimpleCov.start("test_frameworks") { command_name "Minitest" }',
      'gem "minitest"'
    ].join('; ')
    Rake::Task['test'].execute
  end
end

namespace :mime do
  desc "Download the current MIME type registrations from IANA."
  task :iana, [ :destination ] => 'support:nokogiri' do |t, args|
    require 'iana_registry'
    IANARegistry.download(to: args.destination)
  end

  desc "Download the current MIME type configuration from Apache."
  task :apache, [ :destination ] => 'support:nokogiri' do |t, args|
    require 'apache_mime_types'
    ApacheMIMETypes.download(to: args.destination)
  end
end

namespace :convert do
  namespace :docs do
    task :setup do
      gem 'rdoc'
      require 'rdoc/rdoc'
      @doc_converter ||= RDoc::Markup::ToMarkdown.new
    end

    %w(README History History-Types).each do |name|
      file "#{name}.md" => [ "#{name}.rdoc", :setup ] do |t|
        File.open(t.name, 'wb') { |target|
          target.write @doc_converter.convert(IO.read(t.prerequisites.first))
        }
      end

      task docs: [ name ]
    end
  end

  namespace :yaml do
    desc "Convert from YAML to JSON"
    task :json, [ :source, :destination, :multiple_files ] => :support do |t, args|
      require 'convert'
      Convert.from_yaml_to_json(args)
    end
  end

  namespace :json do
    desc "Convert from JSON to YAML"
    task :yaml, [ :source, :destination, :multiple_files ] => :support do |t, args|
      require 'convert'
      Convert.from_json_to_yaml(args)
    end
  end
end

Rake::Task['travis'].prerequisites.replace(%w(test:coveralls))
Rake::Task['gem'].prerequisites.unshift("convert:yaml:json")

# vim: syntax=ruby
