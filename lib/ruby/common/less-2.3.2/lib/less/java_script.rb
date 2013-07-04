module Less
  module JavaScript
    
    def self.default_context_wrapper
      if defined?(JRUBY_VERSION)
        require 'less/java_script/rhino_context'
        RhinoContext
      else
        require 'less/java_script/v8_context'
        V8Context
      end
    end
    
    @@context_wrapper = nil
    
    def self.context_wrapper
      @@context_wrapper ||= default_context_wrapper
    end
    
    def self.context_wrapper=(klass)
      @@context_wrapper = klass
    end
    
    # execute a block as JS
    def self.exec(&block)
      context_wrapper.instance.exec(&block)
    end
    
    def self.eval(source)
      context_wrapper.instance.eval(source)
    end
    
  end
end