module Temple
  module Mixins
    # @api private
    module EngineDSL
      def chain_modified!
      end

      def append(*args, &block)
        chain << chain_element(args, block)
        chain_modified!
      end

      def prepend(*args, &block)
        chain.unshift(chain_element(args, block))
        chain_modified!
      end

      def remove(name)
        name = chain_name(name)
        found = false
        chain.reject! do |i|
          if i.first == name
            found = true
          else
            false
          end
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      alias use append

      def before(name, *args, &block)
        name = chain_name(name)
        e = chain_element(args, block)
        found, i = false, 0
        while i < chain.size
          if chain[i].first == name
            found = true
            chain.insert(i, e)
            i += 2
          else
            i += 1
          end
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      def after(name, *args, &block)
        name = chain_name(name)
        e = chain_element(args, block)
        found, i = false, 0
        while i < chain.size
          if chain[i].first == name
            found = true
            i += 1
            chain.insert(i, e)
          end
          i += 1
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      def replace(name, *args, &block)
        name = chain_name(name)
        e = chain_element(args, block)
        found = false
        chain.each_with_index do |c, i|
          if c.first == name
            found = true
            chain[i] = e
          end
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      # Shortcuts to access namespaces
      { :filter    => Temple::Filters,
        :generator => Temple::Generators,
        :html      => Temple::HTML }.each do |method, mod|
        define_method(method) do |name, *options|
          use(name, mod.const_get(name), *options)
        end
      end

      private

      def chain_name(name)
        name = Class === name ? name.name.to_sym : name
        raise(ArgumentError, 'Name argument must be Class or Symbol') unless Symbol === name
        name
      end

      def chain_class_constructor(filter, option_filter)
        local_options = option_filter.last.respond_to?(:to_hash) ? option_filter.pop.to_hash : {}
        raise(ArgumentError, 'Only symbols allowed in option filter') unless option_filter.all? {|o| Symbol === o }
        define_options(*option_filter) if respond_to?(:define_options)
        proc do |engine|
          filter.new({}.update(engine.options).delete_if {|k,v| !option_filter.include?(k) }.update(local_options))
        end
      end

      def chain_proc_constructor(name, filter)
        raise(ArgumentError, 'Proc or blocks must have arity 0 or 1') if filter.arity > 1
        method_name = "FILTER #{name}"
        if Class === self
          define_method(method_name, &filter)
          filter = instance_method(method_name)
          if filter.arity == 1
            proc {|engine| filter.bind(engine) }
          else
            proc do |engine|
              f = filter.bind(engine).call
              raise 'Constructor must return callable object' unless f.respond_to?(:call)
              f
            end
          end
        else
          (class << self; self; end).class_eval { define_method(method_name, &filter) }
          filter = method(method_name)
          proc {|engine| filter }
        end
      end

      def chain_callable_constructor(filter)
        raise(ArgumentError, 'Class or callable argument is required') unless filter.respond_to?(:call)
        proc {|engine| filter }
      end

      def chain_element(args, block)
        name = args.shift
        if Class === name
          filter = name
          name = filter.name.to_sym
        else
          raise(ArgumentError, 'Name argument must be Class or Symbol') unless Symbol === name
        end

        if block
          raise(ArgumentError, 'Class and block argument are not allowed at the same time') if filter
          filter = block
        end

        filter ||= args.shift

        case filter
        when Proc
          # Proc or block argument
          # The proc is converted to a method of the engine class.
          # The proc can then access the option hash of the engine.
          raise(ArgumentError, 'Too many arguments') unless args.empty?
          [name, chain_proc_constructor(name, filter)]
        when Class
          # Class argument (e.g Filter class)
          # The options are passed to the classes constructor.
          [name, chain_class_constructor(filter, args)]
        else
          # Other callable argument (e.g. Object of class which implements #call or Method)
          # The callable has no access to the option hash of the engine.
          raise(ArgumentError, 'Too many arguments') unless args.empty?
          [name, chain_callable_constructor(filter)]
        end
      end
    end
  end
end
