module Temple
  module HTML
    # This filter merges html attributes (e.g. used for id and class)
    # @api public
    class AttributeMerger < Filter
      define_options :merge_attrs => {'id' => '_', 'class' => ' '}

      def on_html_attrs(*attrs)
        names = []
        values = {}

        attrs.each do |attr|
          name, value = attr[2].to_s, attr[3]
          if values[name]
            raise(FilterError, "Multiple #{name} attributes specified") unless options[:merge_attrs][name]
            values[name] << value
          else
            values[name] = [value]
            names << name
          end
        end

        attrs = names.map do |name|
          value = values[name]
          if (delimiter = options[:merge_attrs][name]) && value.size > 1
            exp = [:multi]
            if value.all? {|v| contains_nonempty_static?(v) }
              exp << value.first
              value[1..-1].each {|v| exp << [:static, delimiter] << v }
              [:html, :attr, name, exp]
            else
              captures = unique_name
              exp << [:code, "#{captures} = []"]
              value.each_with_index {|v, i| exp << [:capture, "#{captures}[#{i}]", v] }
              exp << [:dynamic, "#{captures}.reject(&:empty?).join(#{delimiter.inspect})"]
            end
            [:html, :attr, name, exp]
          else
            [:html, :attr, name, value.first]
          end
        end

        [:html, :attrs, *attrs]
      end
    end
  end
end
