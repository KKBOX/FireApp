module Temple
  module ERB
    # ERB trimming
    # Set option :trim_mode to
    #    <> - omit newline for lines starting with <% and ending in %>
    #    >  - omit newline for lines ending in %>
    #
    # @api public
    class Trimming < Filter
      define_options :trim_mode

      def on_multi(*exps)
        case options[:trim_mode]
        when '>'
          i = 0
          while i < exps.size
            exps.delete_at(i + 1) if code?(exps[i]) && exps[i+1] == [:static, "\n"]
            i += 1
          end
        when '<>'
          i = 0
          while i < exps.size
            exps.delete_at(i + 1) if code?(exps[i]) && exps[i+1] == [:static, "\n"] &&
                                     (!exps[i-1] || (exps[i-1] == [:newline]))
            i += 1
          end
        end
        [:multi, *exps]
      end

      protected

      def code?(exp)
        exp[0] == :escape || exp[0] == :code
      end
    end
  end
end
