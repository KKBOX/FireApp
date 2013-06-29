module Temple
  module Generators
    # Just like Array, but calls #join on the array.
    #
    #   _buf = []
    #   _buf << "static"
    #   _buf << dynamic
    #   _buf.join
    #
    # @api public
    class ArrayBuffer < Array
      def call(exp)
        case exp.first
        when :static
          "#{buffer} = #{exp.last.inspect}"
        when :dynamic
          "#{buffer} = (#{exp.last}).to_s"
        else
          super
        end
      end

      def postamble
        "#{buffer} = #{buffer}.join"
      end
    end
  end
end
