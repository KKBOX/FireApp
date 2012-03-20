require 'java'

require 'rhino/rhino-1.7R3.jar'

module Rhino
  
  # This module contains all the native Rhino objects implemented in Java
  # e.g. Rhino::JS::NativeObject # => org.mozilla.javascript.NativeObject
  module JS
    include_package "org.mozilla.javascript"
    
    module Regexp
      include_package "org.mozilla.javascript.regexp"
    end
    
  end
  
end

require 'rhino/wormhole'
Rhino.extend Rhino::To

require 'rhino/object'
require 'rhino/context'
require 'rhino/error'
require 'rhino/rhino_ext'
require 'rhino/ruby'
require 'rhino/ruby/access'
require 'rhino/deprecations'
