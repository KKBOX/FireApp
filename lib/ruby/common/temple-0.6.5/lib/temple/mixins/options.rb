module Temple
  module Mixins
    # @api public
    module DefaultOptions
      def set_default_options(opts)
        default_options.update(opts)
      end

      def default_options
        @default_options ||= OptionHash.new(superclass.respond_to?(:default_options) ?
                                            superclass.default_options : nil) do |hash, key, deprecated|
          unless @option_validator_disabled
            if deprecated
              warn "Option #{key.inspect} is deprecated by #{self}"
            else
              # TODO: This will raise an exception in the future!
              # raise ArgumentError, "Option #{key.inspect} is not supported by #{self}"
              warn "Option #{key.inspect} is not supported by #{self}"
            end
          end
        end
      end

      def define_options(*opts)
        if opts.last.respond_to?(:to_hash)
          hash = opts.pop.to_hash
          default_options.add_valid_keys(hash.keys)
          default_options.update(hash)
        end
        default_options.add_valid_keys(opts)
      end

      def define_deprecated_options(*opts)
        if opts.last.respond_to?(:to_hash)
          hash = opts.pop.to_hash
          default_options.add_deprecated_keys(hash.keys)
          default_options.update(hash)
        end
        default_options.add_deprecated_keys(opts)
      end

      def disable_option_validator!
        @option_validator_disabled = true
      end
    end

    module ThreadOptions
      def with_options(options)
        old_options = thread_options
        Thread.current[thread_options_key] = ImmutableHash.new(options, thread_options)
        yield
      ensure
        Thread.current[thread_options_key] = old_options
      end

      def thread_options
        Thread.current[thread_options_key]
      end

      protected

      def thread_options_key
        @thread_options_key ||= "#{self.name}-thread-options".to_sym
      end
    end

    # @api public
    module Options
      def self.included(base)
        base.class_eval do
          extend DefaultOptions
          extend ThreadOptions
        end
      end

      attr_reader :options

      def initialize(opts = {})
        self.class.default_options.validate_hash!(opts)
        self.class.default_options.validate_hash!(self.class.thread_options) if self.class.thread_options
        @options = ImmutableHash.new({}.update(self.class.default_options).update(self.class.thread_options || {}).update(opts))
      end
    end
  end
end
