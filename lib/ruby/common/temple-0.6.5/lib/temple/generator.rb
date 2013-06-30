module Temple
  # Abstract generator base class
  # Generators should inherit this class and
  # compile the Core Abstraction to ruby code.
  #
  # @api public
  class Generator
    include Mixins::CompiledDispatcher
    include Mixins::Options

    define_options :capture_generator => 'StringBuffer',
                   :buffer => '_buf'

    def call(exp)
      [preamble, compile(exp), postamble].join('; ')
    end

    def on(*exp)
      raise InvalidExpression, "Generator supports only core expressions - found #{exp.inspect}"
    end

    def on_multi(*exp)
      exp.map {|e| compile(e) }.join('; ')
    end

    def on_newline
      "\n"
    end

    def on_capture(name, exp)
      capture_generator.new(:buffer => name).call(exp)
    end

    def on_static(text)
      concat(text.inspect)
    end

    def on_dynamic(code)
      concat(code)
    end

    def on_code(code)
      code
    end

    protected

    def buffer
      options[:buffer]
    end

    def capture_generator
      @capture_generator ||= Class === options[:capture_generator] ?
      options[:capture_generator] :
        Generators.const_get(options[:capture_generator])
    end

    def concat(str)
      "#{buffer} << (#{str})"
    end
  end
end
