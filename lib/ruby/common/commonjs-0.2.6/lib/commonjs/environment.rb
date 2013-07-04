require 'pathname'
module CommonJS
  class Environment

    attr_reader :runtime

    def initialize(runtime, options = {})
      @runtime = runtime
      @paths = [options[:path]].flatten.map {|path| Pathname(path)}
      @modules = {}
    end

    def require(module_id)
      unless mod = @modules[module_id]
        filepath = find(module_id) or fail LoadError, "no such module '#{module_id}'"
        load = @runtime.eval("(function(module, require, exports) {#{File.read(filepath)}})", filepath.expand_path.to_s)
        @modules[module_id] = mod = Module.new(module_id, self)
        load.call(mod, mod.require_function, mod.exports)
      end
      return mod.exports
    end

    def native(module_id, impl)
      @modules[module_id] = Module::Native.new(impl)
    end

    def new_object
      @runtime['Object'].new
    end

    private

    def find(module_id)
      if loadpath = @paths.find { |path| path.join("#{module_id}.js").exist? }
        loadpath.join("#{module_id}.js")
      end
    end
  end
end
