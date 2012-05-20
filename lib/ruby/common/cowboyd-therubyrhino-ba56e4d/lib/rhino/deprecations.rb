
module Rhino
  
  @@stub_class = Class.new(Object)
  
  def self.const_missing(name)
    case name.to_s
    when 'J' then
      warn "[DEPRECATION] `Rhino::J` is deprecated, use `Rhino::JS` instead."
      return JS
    when 'JavascriptError' then
      warn "[DEPRECATION] `Rhino::JavascriptError` is deprecated, use `Rhino::JSError` instead."
      return JSError
    when 'NativeObject' then
      warn "[DEPRECATION] `Rhino::NativeObject` is no longer used, returning a stub."
      return @@stub_class
    when 'NativeFunction' then
      warn "[DEPRECATION] `Rhino::NativeFunction` is no longer used, returning a stub."
      return @@stub_class
    else super
    end
  end
  
  @@warnings = {}
  
  def self.warn(msg)
    # only print out deprecation warnings once
    if msg[0, 13] == '[DEPRECATION]'
      return nil if @@warnings[msg]
      @@warnings[msg] = true
    end
    super # Kernel.warn
  end
  
  module To
  
    extend self

    # @deprecated use {#to_ruby} instead
    def self.ruby(object)
      Rhino.warn "[DEPRECATION] `Rhino::To.ruby` is deprecated, use `Rhino.to_ruby` instead."
      to_ruby(object)
    end

    # @deprecated use {#to_javascript} instead
    def self.javascript(object, scope = nil) 
      Rhino.warn "[DEPRECATION] `Rhino::To.javascript` is deprecated, use `Rhino.to_javascript` instead."
      to_javascript(object, scope)
    end
  
  end
end
