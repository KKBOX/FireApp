module Temple
  module HTML
    # This filter merges html attributes (e.g. used for id and class)
    # @api public
    class AttributeMerger < Filter
      default_options[:attr_delimiter] = {'id' => '_', 'class' => ' '}

      def on_html_attrs(*attrs)
        names = []
        result = {}
        attrs.each do |attr|
          raise(InvalidExpression, 'Attribute is not a html attr') if attr[0] != :html || attr[1] != :attr
          name, value = attr[2].to_s, attr[3]
          if result[name]
            delimiter = options[:attr_delimiter][name]
            raise "Multiple #{name} attributes specified" unless delimiter
            if empty_exp?(value)
              result[name] = [:html, :attr, name,
                              [:multi,
                               result[name][3],
                               value]]
            elsif contains_static?(value)
              result[name] = [:html, :attr, name,
                              [:multi,
                               result[name][3],
                               [:static, delimiter],
                               value]]
            else
              tmp = unique_name
              result[name] = [:html, :attr, name,
                              [:multi,
                               result[name][3],
                               [:capture, tmp, value],
                               [:if, "!#{tmp}.empty?",
                                [:multi,
                                 [:static, delimiter],
                                 [:dynamic, tmp]]]]]
            end
          else
            result[name] = attr
            names << name
          end
        end
        [:html, :attrs, *names.map {|name| result[name] }]
      end
    end
  end
end
