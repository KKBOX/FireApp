module Temple
  module Filters
    # Remove BOM from input string
    #
    # @api public
    class RemoveBOM < Parser
      def call(s)
        if s.respond_to?(:encoding)
          if s.encoding.name =~ /^UTF-(8|16|32)(BE|LE)?/
            s.gsub(Regexp.new("\\A\uFEFF".encode(s.encoding.name)), '')
          else
            s
          end
        else
          s.gsub(/\A\xEF\xBB\xBF/, '')
        end
      end
    end
  end
end
