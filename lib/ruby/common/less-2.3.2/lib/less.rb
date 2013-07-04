
require 'less/defaults'
require 'less/errors'
require 'less/loader'
require 'less/parser'
require 'less/version'
require 'less/java_script'

module Less
  extend Less::Defaults
  
  # NOTE: keep the @loader as less-rails depends on 
  # it as it overrides some less/tree.js functions!
  @loader = Less::Loader.new
  @less = @loader.require('less/index')

  def self.[](name)
    @less[name]
  end
  
  # exposes less.Parser
  def self.Parser
    self['Parser']
  end

  # exposes less.tree e.g. for attaching custom functions
  # Less.tree.functions['foo'] = lambda { |*args| 'bar' }
  def self.tree
    self['tree']
  end
  
end