module Temple
  module HTML
    # This filter removes empty attributes
    # @api public
    class AttributeRemover < Filter
      default_options[:remove_empty_attrs] = true

      def on_html_attrs(*attrs)
        [:multi, *(options[:remove_empty_attrs] ?
                   attrs.map {|attr| compile(attr) } : attrs)]
      end

      def on_html_attr(name, value)
        if empty_exp?(value)
          value
        elsif contains_static?(value)
          [:html, :attr, name, value]
        else
          tmp = unique_name
          [:multi,
           [:capture, tmp, compile(value)],
           [:if, "!#{tmp}.empty?",
            [:html, :attr, name, [:dynamic, tmp]]]]
        end
      end
    end
  end
end
