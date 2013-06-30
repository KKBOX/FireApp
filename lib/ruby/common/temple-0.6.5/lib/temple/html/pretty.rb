module Temple
  module HTML
    # @api public
    class Pretty < Fast
      define_options :indent => '  ',
                     :pretty => true,
                     :indent_tags => %w(article aside audio base body datalist dd div dl dt
                                        fieldset figure footer form head h1 h2 h3 h4 h5 h6
                                        header hgroup hr html li link meta nav ol p
                                        rp rt ruby section script style table tbody td tfoot
                                        th thead title tr ul video doctype).freeze,
                     :pre_tags => %w(code pre textarea).freeze

      def initialize(opts = {})
        super
        @last = nil
        @indent = 0
        @pretty = options[:pretty]
        @pre_tags = Regexp.new(options[:pre_tags].map {|t| "<#{t}" }.join('|'))
      end

      def call(exp)
        @pretty ? [:multi, preamble, compile(exp)] : super
      end

      def on_static(content)
        if @pretty
          if @pre_tags !~ content
            content = content.sub(/\A\s*\n?/, "\n") if options[:indent_tags].include?(@last)
            content = content.gsub("\n", indent)
          end
          @last = :static
        end
        [:static, content]
      end

      def on_dynamic(code)
        if @pretty
          tmp = unique_name
          indent_code = ''
          indent_code << "#{tmp} = #{tmp}.sub(/\\A\\s*\\n?/, \"\\n\"); " if options[:indent_tags].include?(@last)
          indent_code << "#{tmp} = #{tmp}.gsub(\"\n\", #{indent.inspect}); "
          if ''.respond_to?(:html_safe)
            safe = unique_name
            # we have to first save if the string was html_safe
            # otherwise the gsub operation will lose that knowledge
            indent_code = "#{safe} = #{tmp}.html_safe?; #{indent_code}#{tmp} = #{tmp}.html_safe if #{safe}; "
          end
          @last = :dynamic
          [:multi,
           [:code, "#{tmp} = (#{code}).to_s"],
           [:code, "if #{@pre_tags_name} !~ #{tmp}; #{indent_code}end"],
           [:dynamic, tmp]]
        else
          [:dynamic, code]
        end
      end

      def on_html_doctype(type)
        return super unless @pretty
        [:multi, [:static, tag_indent('doctype')], super]
      end

      def on_html_comment(content)
        return super unless @pretty
        result = [:multi, [:static, tag_indent('comment')], super]
        @last = :comment
        result
      end

      def on_html_tag(name, attrs, content = nil)
        return super unless @pretty

        name = name.to_s
        closed = !content || (empty_exp?(content) && options[:autoclose].include?(name))

        @pretty = false
        result = [:multi, [:static, "#{tag_indent(name)}<#{name}"], compile(attrs)]
        result << [:static, (closed && xhtml? ? ' /' : '') + '>']

        @pretty = !options[:pre_tags].include?(name)
        if content
          @indent += 1
          result << compile(content)
          @indent -= 1
        end
        result << [:static, "#{content && !empty_exp?(content) ? tag_indent(name) : ''}</#{name}>"] unless closed

        @pretty = true
        result
      end

      protected

      def preamble
        @pre_tags_name = unique_name
        [:code, "#{@pre_tags_name} = /#{@pre_tags.source}/"]
      end

      def indent
        "\n" + (options[:indent] || '') * @indent
      end

      # Return indentation before tag
      def tag_indent(name)
        result = @last && (options[:indent_tags].include?(@last) || options[:indent_tags].include?(name)) ? indent : ''
        @last = name
        result
      end
    end
  end
end
