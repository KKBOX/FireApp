require 'tilt'

module Temple
  module Templates
    class Tilt < ::Tilt::Template
      extend Mixins::Template

      define_options :mime_type => 'text/html'

      def self.default_mime_type
        default_options[:mime_type]
      end

      def self.default_mime_type=(mime_type)
        default_options[:mime_type] = mime_type
      end

      # Prepare Temple template
      #
      # Called immediately after template data is loaded.
      #
      # @return [void]
      def prepare
        # Overwrite option: No streaming support in Tilt
        opts = {}.update(self.class.default_options).update(options).update(:file => eval_file, :streaming => false)
        opts.delete(:mime_type)
        opts.delete(:outvar) # Sinatra gives us this invalid variable
        @src = self.class.compile(data, opts)
      end

      # A string containing the (Ruby) source code for the template.
      #
      # @param [Hash]   locals Local variables
      # @return [String] Compiled template ruby code
      def precompiled_template(locals = {})
        @src
      end

      def self.register_as(*names)
        ::Tilt.register(self, *names.map(&:to_s))
      end
    end
  end
end
