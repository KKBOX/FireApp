begin
  require 'rhino' unless defined?(Rhino)
rescue LoadError => e
  warn "[WARNING] Please install gem 'therubyrhino' to use Less under JRuby."
  raise e
end

require 'rhino/version'
if Rhino::VERSION < '2.0.2'
  raise LoadError, "expected gem 'therubyrhino' '>= 2.0.2' but got '#{Rhino::VERSION}'"
end

module Less
  module JavaScript
    class RhinoContext
      
      def self.instance
        return new # NOTE: for Rhino a context should be kept open per thread !
      end
      
      def initialize(globals = nil)
        @rhino_context = Rhino::Context.new :java => true
        if @rhino_context.respond_to?(:version)
          @rhino_context.version = '1.8'
          apply_1_8_compatibility! if @rhino_context.version.to_s != '1.8'
        else
          apply_1_8_compatibility!
        end
        globals.each { |key, val| @rhino_context[key] = val } if globals
      end

      def unwrap
        @rhino_context
      end
      
      def exec(&block)
        @rhino_context.open(&block)
      rescue Rhino::JSError => e
        handle_js_error(e)
      end

      def eval(source, options = {})
        source = source.encode('UTF-8') if source.respond_to?(:encode)
        
        source_name = options[:source_name] || "<eval>"
        line_number = options[:line_number] || 1
        @rhino_context.eval("(#{source})", source_name, line_number)
      rescue Rhino::JSError => e
        handle_js_error(e)
      end

      def call(properties, *args)
        options = args.last.is_a?(::Hash) ? args.pop : {} # extract_option!
        
        source_name = options[:source_name] || "<eval>"
        line_number = options[:line_number] || 1
        @rhino_context.eval(properties, source_name, line_number).call(*args)
      rescue Rhino::JSError => e
        handle_js_error(e)
      end
      
      def method_missing(symbol, *args)
        if @rhino_context.respond_to?(symbol)
          @rhino_context.send(symbol, *args)
        else
          super
        end
      end
      
      private
      
        def handle_js_error(e)
          if e.value && ( e.value['message'] || e.value['type'].is_a?(String) )
            raise Less::ParseError.new(e, e.value) # LessError
          end
          if e.unwrap.to_s =~ /missing closing `\}`/
            raise Less::ParseError.new(e.unwrap.to_s)
          end
          if e.message && e.message[0, 12] == "Syntax Error"
            raise Less::ParseError.new(e)
          else
            raise Less::Error.new(e)
          end          
        end
        
        def apply_1_8_compatibility!
          # TODO rather load ecma-5.js ...
          @rhino_context.eval("
            // String
            if ( ! String.prototype.trim ) {  
              String.prototype.trim = function () {  
                return this.replace(/^\s+|\s+$/g,'');  
              };  
            }
          ")
        end
        
    end
  end
end
