module Temple
  module HTML
    # This filter sorts html attributes.
    # @api public
    class AttributeSorter < Filter
      default_options[:sort_attrs] = true

      def on_html_attrs(*attrs)
        attrs = attrs.sort_by do |attr|
          raise(InvalidExpression, 'Attribute is not a html attr') if attr[0] != :html || attr[1] != :attr
          attr[2].to_s
        end if options[:sort_attrs]
        [:html, :attrs, *attrs]
      end
    end
  end
end
