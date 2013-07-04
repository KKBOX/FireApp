begin
  require 'v8' unless defined?(V8)
rescue LoadError => e
  warn "[WARNING] Please install gem 'therubyracer' to use Less."
  raise e
end

require 'pathname'

module Less
  module JavaScript
    class V8Context

      def self.instance
        return new
      end

      def initialize(globals = nil)
        lock do
          @v8_context = V8::Context.new
          globals.each { |key, val| @v8_context[key] = val } if globals
        end
      end

      def unwrap
        @v8_context
      end

      def exec(&block)
        lock(&block)
      end

      def eval(source, options = nil) # passing options not supported
        source = source.encode('UTF-8') if source.respond_to?(:encode)

        lock do
          @v8_context.eval("(#{source})")
        end
      end

      def call(properties, *args)
        args.last.is_a?(::Hash) ? args.pop : nil # extract_options!

        lock do
          @v8_context.eval(properties).call(*args)
        end
      end

      def method_missing(symbol, *args)
        if @v8_context.respond_to?(symbol)
          @v8_context.send(symbol, *args)
        else
          super
        end
      end

      private

        def lock(&block)
          do_lock(&block)
        rescue V8::JSError => e
          if e.in_javascript?
            js_value = e.value.respond_to?(:'[]')
            name = js_value && e.value["name"]
            constructor = js_value && e.value['constructor']
            if name == "SyntaxError" ||
                ( constructor && constructor.name == "LessError" )
              raise Less::ParseError.new(e, js_value ? e.value : nil)
            end
          # NOTE: less/parser.js :
          #
          #   error = new(LessError)({
          #      index: i,
          #      type: 'Parse',
          #      message: "missing closing `}`",
          #      filename: env.filename
          #   }, env);
          #
          # comes back as value: RuntimeError !
          elsif e.value.to_s =~ /missing closing `\}`/
            raise Less::ParseError.new(e.value.to_s)
          end
          raise Less::Error.new(e)
        end

        def do_lock
          result, exception = nil, nil
          V8::C::Locker() do
            begin
              result = yield
            rescue Exception => e
              exception = e
            end
          end

          if exception
            raise exception
          else
            result
          end
        end

    end
  end
end
