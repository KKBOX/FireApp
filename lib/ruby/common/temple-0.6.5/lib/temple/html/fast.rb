module Temple
  module HTML
    # @api public
    class Fast < Filter
      XHTML_DOCTYPES = {
        '1.1'          => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
        '5'            => '<!DOCTYPE html>',
        'html'         => '<!DOCTYPE html>',
        'strict'       => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
        'frameset'     => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
        'mobile'       => '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">',
        'basic'        => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
        'transitional' => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
      }.freeze

      HTML_DOCTYPES = {
        '5'            => '<!DOCTYPE html>',
        'html'         => '<!DOCTYPE html>',
        'strict'       => '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
        'frameset'     => '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
        'transitional' => '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">',
      }.freeze

      define_options :format => :xhtml,
                     :attr_quote => '"',
                     :autoclose => %w[meta img link br hr input area param col base],
                     :js_wrapper => nil

      HTML = [:html, :html4, :html5]

      def initialize(opts = {})
        super
        unless [:xhtml, *HTML].include?(options[:format])
          raise ArgumentError, "Invalid format #{options[:format].inspect}"
        end
        wrapper = options[:js_wrapper]
        wrapper = xhtml? ? :cdata : :comment if wrapper == :guess
        @js_wrapper =
          case wrapper
          when :comment
            [ "<!--\n", "\n//-->" ]
          when :cdata
            [ "\n//<![CDATA[\n", "\n//]]>\n" ]
          when :both
            [ "<!--\n//<![CDATA[\n", "\n//]]>\n//-->" ]
          when nil
          when Array
            wrapper
          else
            raise ArgumentError, "Invalid JavaScript wrapper #{wrapper.inspect}"
          end
      end

      def xhtml?
        options[:format] == :xhtml
      end

      def html?
        HTML.include?(options[:format])
      end

      def on_html_doctype(type)
        type = type.to_s.downcase

        if type =~ /^xml(\s+(.+))?$/
          raise(FilterError, 'Invalid xml directive in html mode') if html?
          w = options[:attr_quote]
          str = "<?xml version=#{w}1.0#{w} encoding=#{w}#{$2 || 'utf-8'}#{w} ?>"
        elsif html?
          str = HTML_DOCTYPES[type] || raise(FilterError, "Invalid html doctype #{type}")
        else
          str = XHTML_DOCTYPES[type] || raise(FilterError, "Invalid xhtml doctype #{type}")
        end

        [:static, str]
      end

      def on_html_comment(content)
        [:multi,
          [:static, '<!--'],
          compile(content),
          [:static, '-->']]
      end

      def on_html_condcomment(condition, content)
        on_html_comment [:multi,
                         [:static, "[#{condition}]>"],
                         content,
                         [:static, '<![endif]']]
      end

      def on_html_tag(name, attrs, content = nil)
        name = name.to_s
        closed = !content || (empty_exp?(content) && options[:autoclose].include?(name))
        result = [:multi, [:static, "<#{name}"], compile(attrs)]
        result << [:static, (closed && xhtml? ? ' /' : '') + '>']
        result << compile(content) if content
        result << [:static, "</#{name}>"] if !closed
        result
      end

      def on_html_attrs(*attrs)
        [:multi, *attrs.map {|attr| compile(attr) }]
      end

      def on_html_attr(name, value)
        [:multi,
         [:static, " #{name}=#{options[:attr_quote]}"],
         compile(value),
         [:static, options[:attr_quote]]]
      end

      def on_html_js(content)
        if @js_wrapper
          [:multi,
           [:static, @js_wrapper.first],
           compile(content),
           [:static, @js_wrapper.last]]
        else
          compile(content)
        end
      end
    end
  end
end
