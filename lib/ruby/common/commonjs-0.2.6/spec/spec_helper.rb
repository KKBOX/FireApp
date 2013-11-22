
require 'commonjs'
require 'pathname'

def env_with_path_value(path)
  CommonJS::Environment.new new_runtime, :path => path
end

if defined?(JRUBY_VERSION)
  require 'rhino'
  def new_runtime
    Rhino::Context.new
  end
else
  require 'v8'
  def new_runtime
    V8::Context.new
  end
end