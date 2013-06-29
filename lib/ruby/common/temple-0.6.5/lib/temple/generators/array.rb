module Temple
  module Generators
    # Implements an array buffer.
    #
    #   _buf = []
    #   _buf << "static"
    #   _buf << dynamic
    #   _buf
    #
    # @api public
    class Array < Generator
      def preamble
        "#{buffer} = []"
      end

      def postamble
        buffer
      end
    end
  end
end
