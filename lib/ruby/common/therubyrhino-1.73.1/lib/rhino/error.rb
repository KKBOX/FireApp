
module Rhino

  class JSError < StandardError
    
    def initialize(native)
      @native = native # NativeException wrapping a Java Throwable
    end

    def message
      cause ? cause.details : @native.to_s
    end
    
    def to_s
      super
    end
    
    # most likely a Rhino::JS::JavaScriptException
    def cause
      @native.respond_to?(:cause) ? @native.cause : nil
    end

    def unwrap
      return @unwrap if defined?(@unwrap)
      cause = self.cause
      if cause && cause.is_a?(JS::WrappedException) 
        e = cause.getWrappedException
        if e && e.is_a?(Java::OrgJrubyExceptions::RaiseException)
          @unwrap = e.getException
        else
          @unwrap = e
        end
      else
        @unwrap = nil
      end
    end
    
    def javascript_backtrace
      cause.is_a?(JS::RhinoException) ? cause.getScriptStackTrace : nil
    end
    
  end
  
end
