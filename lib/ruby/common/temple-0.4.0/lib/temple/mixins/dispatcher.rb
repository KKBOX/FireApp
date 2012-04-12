module Temple
  module Mixins
    # @api private
    module CoreDispatcher
      def on_multi(*exps)
        multi = [:multi]
        exps.each {|exp| multi << compile(exp) }
        multi
      end

      def on_capture(name, exp)
        [:capture, name, compile(exp)]
      end
    end

    # @api private
    module EscapeDispatcher
      def on_escape(flag, exp)
        [:escape, flag, compile(exp)]
      end
    end

    # @api private
    module ControlFlowDispatcher
      def on_if(condition, *cases)
        [:if, condition, *cases.compact.map {|e| compile(e) }]
      end

      def on_case(arg, *cases)
        [:case, arg, *cases.map {|condition, exp| [condition, compile(exp)] }]
      end

      def on_block(code, content)
        [:block, code, compile(content)]
      end

      def on_cond(*cases)
        [:cond, *cases.map {|condition, exp| [condition, compile(exp)] }]
      end
    end

    # @api private
    module CompiledDispatcher
      def call(exp)
        compile(exp)
      end

      def compile(exp)
        dispatcher(exp)
      end

      private

      def dispatcher(exp)
        replace_dispatcher(exp)
      end

      def replace_dispatcher(exp)
        tree = DispatchNode.new
        dispatched_methods.each do |method|
          method.split('_')[1..-1].inject(tree) {|node, type| node[type.to_sym] }.method = method
        end
        self.class.class_eval %{
          def dispatcher(exp)
            if self.class == #{self.class}
              #{tree.compile}
            else
              replace_dispatcher(exp)
            end
          end
        }
        dispatcher(exp)
      end

      def dispatched_methods
        re = /^on(_[a-zA-Z0-9]+)*$/
        self.methods.map(&:to_s).select(&re.method(:=~))
      end

      # @api private
      class DispatchNode < Hash
        attr_accessor :method

        def initialize
          super { |hsh,key| hsh[key] = DispatchNode.new }
          @method = nil
        end

        def compile(level = 0, parent = nil)
          if empty?
            if method
              ('  ' * level) + "#{method}(*exp[#{level}..-1])"
            elsif !parent
              'exp'
            else
              raise 'Invalid dispatcher node'
            end
          else
            code = [('  ' * level) + "case(exp[#{level}])"]
            each do |key, child|
              code << ('  ' * level) + "when #{key.inspect}"
              code << child.compile(level + 1, parent || method)
            end
            if method || !parent
              code << ('  ' * level) + "else"
              if method
                code << ('  ' * level) + "  #{method}(*exp[#{level}..-1])"
              else
                code << ('  ' * level) + "  exp"
              end
            end
            code << ('  ' * level) + "end"
            code.join("\n")
          end
        end
      end
    end

    # @api public
    #
    # Implements a compatible call-method
    # based on the including classe's methods.
    #
    # It uses every method starting with
    # "on" and uses the rest of the method
    # name as prefix of the expression it
    # will receive. So, if a dispatcher
    # has a method named "on_x", this method
    # will be called with arg0,..,argN
    # whenever an expression like [:x, arg0,..,argN ]
    # is encountered.
    #
    # This works with longer prefixes, too.
    # For example a method named "on_y_z"
    # will be called whenever an expression
    # like [:y, :z, .. ] is found. Furthermore,
    # if additionally a method named "on_y"
    # is present, it will be called when an
    # expression starts with :y but then does
    # not contain with :z. This way a
    # dispatcher can implement namespaces.
    #
    # @note
    #  Processing does not reach into unknown
    #  expression types by default.
    #
    # @example
    #   class MyAwesomeDispatch
    #     include Temple::Mixins::Dispatcher
    #     def on_awesome(thing) # keep awesome things
    #       return [:awesome, thing]
    #     end
    #     def on_boring(thing) # make boring things awesome
    #       return [:awesome, thing+" with bacon"]
    #     end
    #     def on(type,*args) # unknown stuff is boring too
    #       return [:awesome, 'just bacon']
    #     end
    #   end
    #   filter = MyAwesomeDispatch.new
    #   # Boring things are converted:
    #   filter.call([:boring, 'egg']) #=> [:awesome, 'egg with bacon']
    #   # Unknown things too:
    #   filter.call([:foo]) #=> [:awesome, 'just bacon']
    #   # Known but not boring things won't be touched:
    #   filter.call([:awesome, 'chuck norris']) #=>[:awesome, 'chuck norris']
    #
    module Dispatcher
      include CompiledDispatcher
      include CoreDispatcher
      include EscapeDispatcher
      include ControlFlowDispatcher
    end
  end
end
