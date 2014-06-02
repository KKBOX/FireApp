# -*- coding: utf-8 -*-
# This file is borrowed from https://github.com/jlong/serve/blob/master/lib/serve/view_helpers.rb
# Thank http://get-serve.com/

module Serve #:nodoc:
  # Many of the methods here have been extracted in some form from Rails

  module EscapeHelpers
    HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;' }
    JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C' }

    # A utility method for escaping HTML tag characters.
    # This method is also aliased as <tt>h</tt>.
    #
    # In your ERb templates, use this method to escape any unsafe content. For example:
    #   <%=h @person.name %>
    #
    # ==== Example:
    #   puts html_escape("is a > 0 & a < 10?")
    #   # => is a &gt; 0 &amp; a &lt; 10?
    def html_escape(s)
      s.to_s.gsub(/[&"><]/) { |special| HTML_ESCAPE[special] }
    end
    alias h html_escape

    # A utility method for escaping HTML entities in JSON strings.
    # This method is also aliased as <tt>j</tt>.
    #
    # In your ERb templates, use this method to escape any HTML entities:
    #   <%=j @person.to_json %>
    #
    # ==== Example:
    #   puts json_escape("is a > 0 & a < 10?")
    #   # => is a \u003E 0 \u0026 a \u003C 10?
    def json_escape(s)
      s.to_s.gsub(/[&"><]/) { |special| JSON_ESCAPE[special] }
    end
    alias j json_escape
  end

  module ContentHelpers
    def content_for(symbol, content = nil, &block)
      content = capture(&block) if block_given?
      set_content_for(symbol, content) if content
      get_content_for(symbol) unless content
    end

    def content_for?(symbol)
      !(get_content_for(symbol)).nil?
    end

    def get_content_for(symbol = :content)
      if symbol.to_s.intern == :content
        @content
      else
        instance_variable_get("@content_for_#{symbol}")
      end
    end

    def set_content_for(symbol, value)
      instance_variable_set("@content_for_#{symbol}", value)
    end

    def capture_erb(&block)
      buffer = ""
      old_buffer, @_out_buf = @_out_buf, buffer
      yield
      buffer
    ensure
      @_out_buf = old_buffer
    end
    alias capture_rhtml capture_erb
    alias capture_erubis capture_erb
    
    def capture_slim(&block)
      old_buffer = eval  "_buf", block.binding
      eval  "origin_buf,_buf=_buf,[]", block.binding
      capture_content = yield.to_s
      eval  "_buf=origin_buf", block.binding
      capture_content
    ensure
      eval  "_buf=origin_buf", block.binding
    end

    def capture(&block)
      capture_method = "capture_#{script_extension}"
      if respond_to? capture_method
        send capture_method, &block
      else
        raise "Capture not supported for `#{script_extension}' template (#{engine_name})"
      end
    end

    private

      def engine_name
        Tilt[script_extension].to_s
      end

      def script_extension
        parser.script_extension
      end
  end

  module FlashHelpers
    def flash
      @flash ||= {}
    end
  end

  module ParamHelpers

    # Key based access to query parameters. Keys can be strings or symbols.
    def params
      @params ||= request.params
    end

    # Extract the value for a bool param. Handy for rendering templates in
    # different states.
    def boolean_param(key, default = false)
      key = key.to_s.intern
      value = params[key]
      return default if value.blank?
      case value.strip.downcase
        when 'true', '1'  then true
        when 'false', '0' then false
        else raise 'Invalid value'
      end
    end
  end

  module RenderHelpers
    def render(partial, options={})
      if partial.is_a?(Hash)
        options = options.merge(partial)
        partial = options.delete(:partial)
      end
      template = options.delete(:template)
      case
      when partial
        render_partial(partial, options)
      when template
        render_template(template)
      else
        raise "render options not supported #{options.inspect}"
      end
    end

    def render_partial(partial, options={})
      render_template(partial, options.merge(:partial => true))
    end
    alias :partial :render_partial

    def render_template(template, options={})
      path = File.dirname(parser.script_filename)
      if template =~ %r{^/}
        template = template[1..-1]
        path = @root_path
      end
      filename = template_filename(File.join(path, template), :partial => options[:partial])
      if File.file?(filename)
        parser.parse_file(filename, options[:locals])
      else
        raise "File does not exist #{filename.inspect}"
      end
    end

    private

      def template_filename(name, options)
        path = File.dirname(name)
        template = File.basename(name)
        template = "_" + template if options[:partial]
        template += extname(parser.script_filename) unless name =~ /\.[a-z]+$/
        File.join(path, template)
      end

      def extname(filename)
        /(\.[a-z]+\.[a-z]+)$/.match(filename)
        $1 || File.extname(filename) || ''
      end

  end

  module TagHelpers
    def content_tag(name, content, html_options={})
      %{<#{name}#{html_attributes(html_options)}>#{content}</#{name}>}
    end

    def tag(name, html_options={})
      %{<#{name}#{html_attributes(html_options)} />}
    end

    def image_tag(src, html_options = {})
      src = "/#{Compass.configuration.images_dir}/#{src}" unless src =~ /^(https?:|\/)/

      tag(:img, html_options.merge({:src=>src}))
    end

    def image(name, options = {})
      image_tag(ensure_path(ensure_extension(name, 'png'), 'images'), options)
    end

    def javascript_tag(content = nil, html_options = {})
      content_tag(:script, javascript_cdata_section(content), html_options.merge(:type => "text/javascript"))
    end

    def link_to(name, href, html_options = {})
      html_options = html_options.stringify_keys
      confirm = html_options.delete("confirm")
      onclick = "if (!confirm('#{html_escape(confirm)}')) return false;" if confirm
      content_tag(:a, name, html_options.merge(:href => href, :onclick=>onclick))
    end

    def link_to_function(name, *args, &block)
      html_options = extract_options!(args)
      function = args[0] || ''
      onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
      href = html_options[:href] || '#'
      content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
    end

    def mail_to(email_address, name = nil, html_options = {})
      html_options = html_options.stringify_keys
      encode = html_options.delete("encode").to_s
      cc, bcc, subject, body = html_options.delete("cc"), html_options.delete("bcc"), html_options.delete("subject"), html_options.delete("body")

      string = ''
      extras = ''
      extras << "cc=#{CGI.escape(cc).gsub("+", "%20")}&" unless cc.nil?
      extras << "bcc=#{CGI.escape(bcc).gsub("+", "%20")}&" unless bcc.nil?
      extras << "body=#{CGI.escape(body).gsub("+", "%20")}&" unless body.nil?
      extras << "subject=#{CGI.escape(subject).gsub("+", "%20")}&" unless subject.nil?
      extras = "?" << extras.gsub!(/&?$/,"") unless extras.empty?

      email_address = email_address.to_s

      email_address_obfuscated = email_address.dup
      email_address_obfuscated.gsub!(/@/, html_options.delete("replace_at")) if html_options.has_key?("replace_at")
      email_address_obfuscated.gsub!(/\./, html_options.delete("replace_dot")) if html_options.has_key?("replace_dot")

      if encode == "javascript"
        "document.write('#{content_tag("a", name || email_address_obfuscated, html_options.merge({ "href" => "mailto:"+email_address+extras }))}');".each_byte do |c|
          string << sprintf("%%%x", c)
        end
        "<script type=\"#{Mime::JS}\">eval(decodeURIComponent('#{string}'))</script>"
      elsif encode == "hex"
        email_address_encoded = ''
        email_address_obfuscated.each_byte do |c|
          email_address_encoded << sprintf("&#%d;", c)
        end

        protocol = 'mailto:'
        protocol.each_byte { |c| string << sprintf("&#%d;", c) }

        email_address.each_byte do |c|
          char = c.chr
          string << (char =~ /\w/ ? sprintf("%%%x", c) : char)
        end
        content_tag "a", name || email_address_encoded, html_options.merge({ "href" => "#{string}#{extras}" })
      else
        content_tag "a", name || email_address_obfuscated, html_options.merge({ "href" => "mailto:#{email_address}#{extras}" })
      end
    end

    # Generates JavaScript script tags for the sources given as arguments.
    #
    # If the .js extension is not given, it will be appended to the source.
    #
    # Examples
    #     javascript_include_tag 'application' # =>
    #       <script src="/javascripts/application.js" type="text/javascript" />
    #
    #     javascript_include_tag 'https://cdn/jquery.js' # =>
    #       <script src="https://cdn/jquery.js" type="text/javascript" />
    #
    #     javascript_include_tag 'application', 'books' # =>
    #       <script src="/javascripts/application.js" type="text/javascript" />
    #       <script src="/javascripts/books.js" type="text/javascript" />
    #
    def javascript_include_tag(*sources)
      options = extract_options!(sources)

      base_folder = if defined? Compass
                      Compass.configuration.javascripts_dir
                    else
                      'javascripts'
                    end
      sources.map do |source|

        content_tag('script', '', {
          'type' => 'text/javascript',
          'src' => ensure_path(ensure_extension(source, 'js'), base_folder)
        }.with_indifferent_access.merge(options))
      end.join("\n")
    end

    # Generates stylesheet link tags for the sources given as arguments.
    #
    # If the .css extension is not given, it will be appended to the source.
    #
    # Examples
    #     stylesheet_link_tag 'screen' # =>
    #       <link href="/stylesheets/screen.css" media="screen" rel="stylesheet" type="text/css" />
    #
    #     stylesheet_link_tag 'print', :media => 'print' # =>
    #       <link href="/stylesheets/print.css" media="print" rel="stylesheet" type="text/css" />
    #
    #     stylesheet_link_tag 'application', 'books', 'authors' # =>
    #       <link href="/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />
    #       <link href="/stylesheets/books.css" media="screen" rel="stylesheet" type="text/css" />
    #       <link href="/stylesheets/authors.css" media="screen" rel="stylesheet" type="text/css" />
    #
    def stylesheet_link_tag(*sources)
      options = extract_options!(sources)

      base_folder = if defined? Compass
                      Compass.configuration.css_dir
                    else
                      'stylesheets'
                    end
      sources.map do |source|
        tag('link', {
          'rel' => 'stylesheet',
          'type' => 'text/css',
          'media' => 'screen',
          'href' => ensure_path(ensure_extension(source, 'css'), base_folder)
        }.with_indifferent_access.merge(options))
      end.join("\n")
    end

    # form https://github.com/livereload/livereload-js
    def livereload_js
      text = <<END
<script>document.write('<script src="http://' + (location.host || 'localhost').split(':')[0] + ':35729/livereload.js?snipver=1"></' + 'script>')</script>
END
    end

    private

      def cdata_section(content)
        "<![CDATA[#{content}]]>"
      end

      def javascript_cdata_section(content) #:nodoc:
        "\n//#{cdata_section("\n#{content}\n//")}\n"
      end

      def html_attributes(options)
        unless options.blank?
          attrs = []
          options.each_pair do |key, value|
            if value == true
              attrs << %(#{key}="#{key}") if value
            else
              attrs << %(#{key}="#{value}") unless value.nil?
            end
          end
          " #{attrs.sort * ' '}" unless attrs.empty?
        end
      end

      # Ensures a proper extension is appended to the filename.
      #
      # If a URI with the http or https scheme name is given, it is assumed
      # to be absolute and will not be altered.
      #
      # Examples
      #     ensure_extension('screen', 'css') => 'screen.css'
      #     ensure_extension('screen.css', 'css') => 'screen.css'
      #     ensure_extension('jquery.min', 'js') => 'jquery.min.js'
      #     ensure_extension('https://cdn/jquery', 'js') => 'https://cdn/jquery'
      #
      def ensure_extension(source, extension)
        if source =~ /^https?:/ || source.end_with?(".#{extension}")
          return source
        end

        "#{source}.#{extension}"
      end

      # Ensures the proper path to the given source.
      #
      # If the source begins at the root of the public directory or is a URI
      # with the http or https scheme name, it is assumed to be absolute and
      # will not be altered.
      #
      # Examples
      #     ensure_path('screen.css', 'stylesheets') => '/stylesheets/screen.css'
      #     ensure_path('/screen.css', 'stylesheets') => '/screen.css'
      #     ensure_path('http://cdn/jquery.js', 'javascripts') => 'http://cdn/jquery.js'
      #
      def ensure_path(source, path)
        if source =~ /^(\/|https?)/
          return source
        end

        File.join('', path, source)
      end

      # Returns a hash of options if they exist at the end of an array.
      #
      # This is useful when working with splats.
      #
      # Examples
      #     extract_options!([1, 2, { :name => 'sunny' }]) => { :name => 'sunny' }
      #     extract_options!([1, 2, 3]) => {}
      #
      def extract_options!(array)
        array.last.instance_of?(Hash) ? array.pop : {}
      end
  end

  # This module is borrowed from https://github.com/blahed/frank/blob/master/lib/frank/lorem.rb
  module LoremHelpers
    WORDS = %w(alias consequatur aut perferendis sit voluptatem accusantium doloremque aperiam eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo aspernatur aut odit aut fugit sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt neque dolorem ipsum quia dolor sit amet consectetur adipisci velit sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem ut enim ad minima veniam quis nostrum exercitationem ullam corporis nemo enim ipsam voluptatem quia voluptas sit suscipit laboriosam nisi ut aliquid ex ea commodi consequatur quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae et iusto odio dignissimos ducimus qui blanditiis praesentium laudantium totam rem voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident sed ut perspiciatis unde omnis iste natus error similique sunt in culpa qui officia deserunt mollitia animi id est laborum et dolorum fuga et harum quidem rerum facilis est et expedita distinctio nam libero tempore cum soluta nobis est eligendi optio cumque nihil impedit quo porro quisquam est qui minus id quod maxime placeat facere possimus omnis voluptas assumenda est omnis dolor repellendus temporibus autem quibusdam et aut consequatur vel illum qui dolorem eum fugiat quo voluptas nulla pariatur at vero eos et accusamus officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae itaque earum rerum hic tenetur a sapiente delectus ut aut reiciendis voluptatibus maiores doloribus asperiores repellat)

    def lorem_word(replacement = nil)
      lorem_words 1, replacement
    end

    def lorem_words(total, replacement = nil)
      if replacement
        replacement
      else
        (1..total).map do
          randm(WORDS)
        end.join(' ')
      end
    end

    def lorem_sentence(replacement = nil)
      lorem_sentences 1, replacement
    end

    def lorem_sentences(total, replacement = nil)
      # TODO: Don't capitalize replacement field
      if replacement
        replacement
      else
        (1..total).map do
          lorem_words(randm(4..15)).capitalize
        end.join('. ')
      end
    end

    def lorem_paragraph(replacement = nil)
      lorem_paragraphs 1, replacement
    end

    def lorem_paragraphs(total, replacement = nil)
      if replacement
        replacement
      else
        (1..total).map do
          lorem_sentences(randm(3..7), replacement).capitalize
        end.join("\n\n")
      end
    end

    def lorem_date(fmt = '%a %b %d, %Y', range = 1950..2010, replacement = nil)
      if replacement
        replacement
      else
        y = rand(range.last - range.first) + range.first
        m = rand(12) + 1
        d = rand(31) + 1
        Time.local(y,m,d).strftime(fmt)
      end
    end

    def lorem_name(replacement = nil)
      if replacement
        replacement
      else
        "#{lorem_first_name} #{lorem_last_name}"
      end
    end

    def lorem_first_name(replacement = nil)
      if replacement
        replacement
      else
        names = %w(Judith Angelo Margarita Kerry Elaine Lorenzo Justice Doris Raul Liliana Kerry Elise Ciaran Johnny Moses Davion Penny Mohammed Harvey Sheryl Hudson Brendan Brooklynn Denis Sadie Trisha Jacquelyn Virgil Cindy Alexa Marianne Giselle Casey Alondra Angela Katherine Skyler Kyleigh Carly Abel Adrianna Luis Dominick Eoin Noel Ciara Roberto Skylar Brock Earl Dwayne Jackie Hamish Sienna Nolan Daren Jean Shirley Connor Geraldine Niall Kristi Monty Yvonne Tammie Zachariah Fatima Ruby Nadia Anahi Calum Peggy Alfredo Marybeth Bonnie Gordon Cara John Staci Samuel Carmen Rylee Yehudi Colm Beth Dulce Darius inley Javon Jason Perla Wayne Laila Kaleigh Maggie Don Quinn Collin Aniya Zoe Isabel Clint Leland Esmeralda Emma Madeline Byron Courtney Vanessa Terry Antoinette George Constance Preston Rolando Caleb Kenneth Lynette Carley Francesca Johnnie Jordyn Arturo Camila Skye Guy Ana Kaylin Nia Colton Bart Brendon Alvin Daryl Dirk Mya Pete Joann Uriel Alonzo Agnes Chris Alyson Paola Dora Elias Allen Jackie Eric Bonita Kelvin Emiliano Ashton Kyra Kailey Sonja Alberto Ty Summer Brayden Lori Kelly Tomas Joey Billie Katie Stephanie Danielle Alexis Jamal Kieran Lucinda Eliza Allyson Melinda Alma Piper Deana Harriet Bryce Eli Jadyn Rogelio Orlaith Janet Randal Toby Carla Lorie Caitlyn Annika Isabelle inn Ewan Maisie Michelle Grady Ida Reid Emely Tricia Beau Reese Vance Dalton Lexi Rafael Makenzie Mitzi Clinton Xena Angelina Kendrick Leslie Teddy Jerald Noelle Neil Marsha Gayle Omar Abigail Alexandra Phil Andre Billy Brenden Bianca Jared Gretchen Patrick Antonio Josephine Kyla Manuel Freya Kellie Tonia Jamie Sydney Andres Ruben Harrison Hector Clyde Wendell Kaden Ian Tracy Cathleen Shawn)
        names[rand(names.size)]
      end
    end

    def lorem_last_name(replacement = nil)
      if replacement
        replacement
        else
        names = %w(Chung Chen Melton Hill Puckett Song Hamilton Bender Wagner McLaughlin McNamara Raynor Moon Woodard Desai Wallace Lawrence Griffin Dougherty Powers May Steele Teague Vick Gallagher Solomon Walsh Monroe Connolly Hawkins Middleton Goldstein Watts Johnston Weeks Wilkerson Barton Walton Hall Ross Chung Bender Woods Mangum Joseph Rosenthal Bowden Barton Underwood Jones Baker Merritt Cross Cooper Holmes Sharpe Morgan Hoyle Allen Rich Rich Grant Proctor Diaz Graham Watkins Hinton Marsh Hewitt Branch Walton O'Brien Case Watts Christensen Parks Hardin Lucas Eason Davidson Whitehead Rose Sparks Moore Pearson Rodgers Graves Scarborough Sutton Sinclair Bowman Olsen Love McLean Christian Lamb James Chandler Stout Cowan Golden Bowling Beasley Clapp Abrams Tilley Morse Boykin Sumner Cassidy Davidson Heath Blanchard McAllister McKenzie Byrne Schroeder Griffin Gross Perkins Robertson Palmer Brady Rowe Zhang Hodge Li Bowling Justice Glass Willis Hester Floyd Graves Fischer Norman Chan Hunt Byrd Lane Kaplan Heller May Jennings Hanna Locklear Holloway Jones Glover Vick O'Donnell Goldman McKenna Starr Stone McClure Watson Monroe Abbott Singer Hall Farrell Lucas Norman Atkins Monroe Robertson Sykes Reid Chandler Finch Hobbs Adkins Kinney Whitaker Alexander Conner Waters Becker Rollins Love Adkins Black Fox Hatcher Wu Lloyd Joyce Welch Matthews Chappell MacDonald Kane Butler Pickett Bowman Barton Kennedy Branch Thornton McNeill Weinstein Middleton Moss Lucas Rich Carlton Brady Schultz Nichols Harvey Stevenson Houston Dunn West O'Brien Barr Snyder Cain Heath Boswell Olsen Pittman Weiner Petersen Davis Coleman Terrell Norman Burch Weiner Parrott Henry Gray Chang McLean Eason Weeks Siegel Puckett Heath Hoyle Garrett Neal Baker Goldman Shaffer Choi Carver)
        names[rand(names.size)]
      end
    end

    def lorem_email(replacement = nil)
      if replacement
        replacement
      else
        delimiters = [ '_', '-', '' ]
        domains = %w(gmail.com yahoo.com hotmail.com email.com live.com me.com mac.com aol.com fastmail.com mail.com)
        username = lorem_name.gsub(/[^\w]/, delimiters[rand(delimiters.size)])
        "#{username}@#{domains[rand(domains.size)]}".downcase
      end
    end


    def lorem_image(size, options={})
      if options[:replacement]
        options[:replacement]
      else
        src              = "http://placehold.it/#{size}"
        hex              = %w[a b c d e f 0 1 2 3 4 5 6 7 8 9]
        background_color = options[:background_color]
        color            = options[:color]

        if options[:random_color]
          background_color = hex.shuffle[0...6].join
          color = hex.shuffle[0...6].join
        end

        src << "/#{background_color.sub(/^#/, '')}" if background_color
        src << "/ccc" if background_color.nil? && color
        src << "/#{color.sub(/^#/, '')}" if color
        src << "&text=#{h(options[:text])}" if options[:text]

        src
      end
    end

    private

    def randm(range)
      a = range.to_a
      a[rand(a.length)]
    end
  end

  # from https://github.com/gugod/zh-lorem/blob/master/lib/zh-lorem.rb
  module ZhLoremHelpers
    def zh_lorem_name(replacement = nil)
      if replacement
        replacement
      else
        zh_lorem_last_name + zh_lorem_first_name
      end
    end

    def zh_lorem_name_pinyin(replacement = nil)
      if replacement
        return replacement
      end

      return zh_lorem_first_name_pinyin + " " + zh_lorem_last_name_pinyin
    end

    def zh_lorem_first_name(replacement = nil)
      if replacement
        return replacement
      end

      x = %w[世 中 仁 伶 佩 佳 俊 信 倫 偉 傑 儀 元 冠 凱 君 哲 嘉 國 士 如 娟 婷 子 孟 宇 安 宏 宗 宜 家 建 弘 強 彥 彬 德 心 志 忠 怡 惠 慧 慶 憲 成 政 敏 文 昌 明 智 曉 柏 榮 欣 正 民 永 淑 玉 玲 珊 珍 珮 琪 瑋 瑜 瑞 瑩 盈 真 祥 秀 秋 穎 立 維 美 翔 翰 聖 育 良 芬 芳 英 菁 華 萍 蓉 裕 豪 貞 賢 郁 鈴 銘 雅 雯 霖 青 靜 韻 鴻 麗 龍]
      return x[rand(x.size)] + (rand(2) == 0 ? "" : x[rand(x.size)])
    end

    def zh_lorem_first_name_pinyin(replacement = nil)
      if replacement
        return replacement
      end
      x = %w[Lee Wang Chang Liu Cheng Yang Huang Zhao Zho Wu Schee Sun Zhu Ma Hu Guo Lin Ho Kao Liang Zheng Luo Sung Hsieh Tang Han Cao Xu Deng Xiao Feng Tseng Tsai Peng Pan Yuan Yu Tong Su Ye Lu Wei Jiang Tian Tu Ting Shen Jiang Fan Fu Zhong Lu Wang Dai Cui Ren Liao Yiao Fang Jin Qiu Xia Jia Chu Shi Xiong Meng Qin Yan Xue Ho Lei Bai Long Duan Hao Kong Shao Shi Mao Wan Gu Lai Kang He Yi Qian Niu Hung Gung]

      return x[rand(x.size)] + (rand(2) == 0 ? "" : x[rand(x.size)].downcase)
    end

    def zh_lorem_last_name(replacement = nil)
      if replacement
        return replacement
      end

      x = %w[李 王 張 劉 陳 楊 黃 趙 周 吳 徐 孫 朱 馬 胡 郭 林 何 高 梁 鄭 羅 宋 謝 唐 韓 曹 許 鄧 蕭 馮 曾 程 蔡 彭 潘 袁 於 董 餘 蘇 葉 呂 魏 蔣 田 杜 丁 沈 姜 範 江 傅 鐘 盧 汪 戴 崔 任 陸 廖 姚 方 金 邱 夏 譚 韋 賈 鄒 石 熊 孟 秦 閻 薛 侯 雷 白 龍 段 郝 孔 邵 史 毛 常 萬 顧 賴 武 康 賀 嚴 尹 錢 施 牛 洪 龔]
      return x[rand(x.size)]
    end

    def zh_lorem_last_name_pinyin(replacement = nil)
      if replacement
        return replacement
      end

      x = %w[Li Wang Zhang Liu Chen Yang Huang Zhao Zhou Wu Xu Sun Zhu Ma Hu Guo Lin He Gao Liang Zheng Luo Song Xie Tang Han Cao Deng Xiao Feng Ceng Cheng Cai Peng Pan Yuan Dong Yu Su She Lu: Wei Jiang Tian Du Ding Chen/shen Fan Fu Zhong Lu Dai Cui Ren Liao Yao Fang Jin Qiu Jia Tan Gu Zou Dan Xiong Meng Qin Yan Xue Hou Lei Bai Long Duan Hao Kong Shao Shi Mao Chang Wan Lai Kang Yin Qian Niu Hong Gong]
      return x[rand(x.size)]
    end

    def zh_lorem_email(replacement = nil)
      if replacement
        return replacement
      end

      delimiters = [ '_', '-', '' ]
      domains = %w(gmail.com yahoo.com.tw mail2000.com.tw mac.com example.com.tw ms42.hinet.net mail.notu.edu.tw)
      username = zh_lorem_first_name_pinyin + zh_lorem_last_name_pinyin
      return "#{username}@#{domains[rand(domains.size)]}".downcase
    end

    SENTENCES = [["一個有年紀的人，","一個較大的孩子說，","一到夜裡，","一到過年，","一勺冰水，","一夜的花費，","一婦人說，","一寸光陰一寸金，","一年的設定，","一時看鬧熱的人，","一箇來往的禮節，","一絲絲涼爽秋風，","一綵綵霜痕，","一邊的行列，","一陣吶喊的聲浪，","一顆銀亮亮的月球，","一類的試筆詩，","下半天的談判，","不問是誰，","不懷著危險的恐懼，","不斷地逝去，","不是容易就能奏功，","不是有學士有委員，","不是皆發了幾十萬，","不曉得我的目的，","不曉得誰創造的，","不曉得順這機會，","不用摸索，","不知是兄哥或小弟，","不知行有多少時刻，","不知談論些什麼，","不聲不響地，","不股慄不內怯，","不能成功，","不能隨即回家，","不要爭一爭氣，","不論什麼階級的人，","不讓星星的光明，","不趕他出去，","不遇著危險，","不過隨意做作而已，","不顧慮傍人，","且新正閒著的時候，","丙喝一喝茶，","丙論辯似的說，","丙驚疑地問，","乙感嘆地說，","乙接著嘴說，","也不知什麼是方向，","也因為地面的崎嶇，","也就不容易，","也就便宜，","也就分外著急，","也是不受後母教訓，","也是不容易，","也是經驗不到，","也有他們一種曆，","互有參差，","互相信賴，","互相提攜而前進，","互相提攜，","亦都出去了，","人們不預承認，","人們多不自量，","人們怎地在心境上，","人們的信仰，","什麼樣子，","他不和人家分擔，","他倆不想到休息，","他倆人中的一個，","他倆便也攜著手，","他倆感到有一種，","他倆本無分別所行，","他倆疲倦了，","他們偏不採用，","他們在平時，","他叩了不少下頭，","他的伴侶，","他說人們是在發狂，","他那麼盡力，","他高興的時候，","以樂其心志，","任便人家笑罵，","似也有稍遲緩，","似報知人們，","似皆出門去了，","但在手面趁吃人，","但現在的曆法，","但這是所謂大勢，","住在福戶內的人，","何故世上的人類們，","併也不見陶醉，","使勞動者們，","使成粉末，","來浪費有用的金錢，","便說這卑怯的生命，","保不定不鬧出事來，","借著拜年的名目，","做事業的人們，","偷得空間，","傳播到廣大空間去，","像日本未來的時，","像這樣子鬧下去，","兄弟們到這樣時候，","先先後後，","光明已在前頭，","全數花掉，","典衫當被，","再回到現實世界，","再鬧下去，","別地方是什麼樣子，","到大街上玩去罷，","刺腳的荊棘，","剛纔經市長一說，","務使春風吹來，","包圍住這人世間，","十五年前的熱鬧，","卻不能稍超興奮，","卻自甘心著，","又有不可得的快樂，","又有人不平地說，","只些婦女們，","只在我們貴地，","只是前進，","只有乘這履端初吉，","只有前進，","只有風先生的慇懃，","只殘存些婦女小兒，","可以借它的魔力，","各個兒指手畫腳，","各要爭個體面，","同在這顆地球上，","向面的所向，","呻呻吟吟，","和其哀情，","和別的其餘的一日，","和狺狺的狗吠，","和純真的孩童們，","和電柱上路燈，","四城門的競爭，","四方雲集，","因一邊還都屬孩子，","因為一片暗黑，","因為市街的鬧熱日，","因為所規定的過年，","因為空間的黑暗，","因為這是親戚間，","團團地坐著，","在一個晚上，","在一處的客廳裡，","在一邊誘惑我，","在他們社會裡，","在以前任怎地追憶，","在做頭老的，","在冷靜的街尾，","在冷風中戰慄著，","在和他們同一境遇，","在幾千年前，","在成堆的人們中，","在我回憶裡，","在我的知識程度裡，","在煙縷繚繞的中間，","在環繞太陽運轉，","在這時候，","在這樣黑暗之下，","在這次血祭壇上，","在這黑暗之中，","在這黑暗統治之下，","地方自治的權能，","地球繞著太陽，","多亂惱惱地熱鬧著，","天體的現象嗎，","失了伴侶的他，","奉行正朔，","好久已無聲響的雷，","媽祖的靈應，","孩子們回答著，","孩子們得到指示，","孩子們的事，","孩子們辯說，","孩子般的眼光，","完全不同日子，","完全打消了，","家門有興騰的氣象，","富豪是先天所賦與，","實在也就難怪，","實在可憐可恨，","將腦髓裡驅逐，","小子不長進，","少年已去金難得，","就一味地吶喊著，","就可觸到金錢，","就是那些文人韻士，","就發達繁昌起來，","就說不關什麼，","居然宣佈了戰爭，","已不成功了，","已經準備下，","已經財散人亡，","已闢農場已築家室，","平生慣愛咬文嚼字，","店舖簷前的天燈，","張開他得意的大口，","強盛到肉體的增長，","得了新的刺激，","心裡不懷抱驚恐，","忘卻了溪和水，","忘記他的伴侶，","快樂的追求，","忽然地顛蹶，","忽起眩暈，","怕大家都記不起了，","思想也漸糢糊起來，","恍惚有這呼聲，","悠揚地幾聲洞簫，","想因為腳有些疲軟，","愈會賺錢，","愈要追尋快樂，","愈覺得金錢的寶貴，","意外地竟得生存，","慢慢地說，","憑我們有這一身，","我不明白，","我們是在空地上，","我們有這雙腕，","我們處在這樣環境，","我在兒童時代，","我的意見，","我記得還似昨天，","所以也不擔心到，","所以家裡市上，","所以窮的人，","所以這一回，","所以那邊的街市，","所有一切，","所有無謂的損失，","所謂雪恥的競爭，","所謂風家也者，","手一插進衣袋，","把她清冷冷的光輝，","抵當賓客的使費，","抹著一縷兩縷白雲，","拔去了不少，","捧出滿腔誠意，","接著又說，","接連鬥過兩三晚，","握著有很大權威，","揭破死一般的重幕，","擋不住大的拳頭，","放下茶杯，","放不少鞭炮，","放射到地平線以外，","救死且沒有工夫，","新年的一日，","旗鼓的行列，","既不能把它倆，","日頭是自東徂西，","早幾點鐘解決，","春五正月，","昨晚曾賜過觀覽，","是不容有異議，","是抱著滿腹的憤氣，","是社會的一成員，","是道路或非道路，","是黑暗的晚上，","時間的進行，","暗黑的氣氛，","有一陣孩子們，","有什麼科派捐募，","有時再往親戚家去，","有最古的文明，","有的孩子喊著，","未嘗有人敢自看輕，","某某和某等，","樹要樹皮人要麵皮，","橋柱是否有傾斜，","橋梁是否有斷折，","正可養成競爭心，","死鴨子的嘴吧，","比較兒童時代，","汝算不到，","沒有年歲，","波湧似的，","泰然前進，","溪的廣闊，","溺人的水窪，","滾到了天半，","漸被遮蔽，","濛迷地濃結起來，","無奈群眾的心裡，","熱血正在沸騰，","燈火星星地，","現在不高興了，","現在只有覺悟，","現在想沒得再一個，","現在的我，","生性如此，","生的糧食儘管豐富，","由我的生的行程中，","由深藍色的山頭，","由著裊裊的晚風，","由隘巷中走出來，","甲微喟的說，","甲憤憤地罵，","甲興奮地說，","略一對比，","當科白尼還未出世，","看我們現在，","看見有幾次的變遷，","看見鮮紅的血，","眩眼一縷的光明，","礙步的石頭，","福戶內的事，","禮義之邦的中國，","究竟為的是什麼，","笑掉了齒牙，","第一浮上我的思想，","筋肉比較的瘦弱，","籠罩著街上的煙，","精神上多有些緊張，","約同不平者的聲援，","統我的一生到現在，","經過了很久，","經過幾許途程，","經驗過似的鄭重說，","繞著亭仔腳柱，","纔見有些白光，","美惡竟不會分別，","老人感慨地說，","聽說市長和郡長，","聽說有人在講和，","聽說路關鐘鼓，","能夠合官廳的意思，","自己走出家來，","自鳴得意，","花去了幾千塊，","花各人自己的錢，","若會賺錢，","草繩上插的香條，","蔥惶回顧，","行動上也有些忙碌，","行行前進，","街上看鬧熱的人，","街上還是鬧熱，","街上頓添一種活氣，","被他們欺負了，","被另一邊阻撓著，","被風的歌唱所鼓勵，","要損他一文，","要是說一聲不肯，","要趁節氣，","親戚們多贊稱我，","覺得分外悠遠，","觸進人們的肌膚，","試把這箇假定廢掉，","說了不少好話，","說什麼爭氣，","說我乖巧識禮，","說是沒有法子的事，","誰都有義務分擔，","議論已失去了熱烈，","讓他獨自一個，","走過了一段里程，","身量雖然較高，","輕輕放棄，","輾轉運行，","農民播種犁田，","透過了衣衫，","這一句千古名言，","這一點不能明白，","這些談論的人，","這回在奔走的人，","這天大的奇變，","這幾聲呼喊，","這澎湃聲中，","這說是野蠻的慣習，","這邊門口幾人，","通溶化在月光裡，","連哼的一聲亦不敢，","連生意本，","進來的人說，","遂亦不受到阻礙，","遂有人出來阻擋，","過了些時，","過年種種的預備，","還是孱弱的可憐，","還有閒時間，","那三種曆法，","那不知去處的前途，","那些富家人，","那時代的一年，","那更不成問題，","那末地球運行最初，","那邊亭仔腳幾人，","那邊有些人，","都很讚成，","金錢愈不能到手，","金錢的問題，","金錢的慾念，","銅鑼響亮地敲起來，","錢的可能性愈少，","鑼的響聲，","鑼聲亦不響了，","阻斷爭論，","除廢掉舊曆，","陷人的泥澤，","雖亦有人反對，","雖則不知，","雖受過欺負，","雖未見到結論，","雖遇有些顛蹶，","雨太太的好意，","音響的餘波，","風雨又調和著節奏，","驟然受到光的刺激，","體軀支持不住了，","鬧熱到了，","鬧過別一邊去，","一份貼心，","一天弄的出標書，","一封簡訊，","一通電話，","上了一課，","下了18顆，","下午開個反應，","下班時間忙，","不加糖就苦，","不是不好，","今天大哥說，","你家音響好像不賴，","全台有感，","別人可以回答雀巢，","加太多就膩，","反正他喜歡，","另一本都市的書，","只有中國酒店，","可以回答卡布奇諾，","可以回答曼特寧，","可是我忘了，","台南現在好舒服，","吃了水餃6顆，","呢個禮拜，","咖啡排骨，","咖啡效果好的驚人，","咖啡苦了一點，","喝了一口咖啡，","喝了杯咖啡，","喝咖啡帶個電腦，","因為等它滴完，","地殼先上下跳動，","地震發生時，","就好像咖啡，","就算加了再多糖，","想泡杯燕麥片，","我最愛的鴨頸，","我要去死了，","把民眾嚇了一大跳，","整理理不清的情緒，","早上喝著咖啡，","早晨七點，","明天還得進行核對，","昨天煮水餃，","昨晚喝了三杯，","晚上早早走人，","最終發現，","有些餓了翻身下床，","有人醉酒有人醉茶，","本日連假第三天，","沒了你在身邊，","犧牲自己的假期，","現在台南好悶熱，","現在在煎蛋，","疲憊不堪，","看來又得喝杯咖啡，","睡到下午下台中，","神馬狀況，","第二杯咖啡，","結果一晚上睡不著，","結果被數落了一下，","胃就不行了，","要好好記得，","買了個越南壺，","輕輕一扯，","隔壁的老兄，","面包已經烤好了，","驗屍似詳檢，"],["一層層堆聚起來。","不停地前進。","不可讓他佔便宜。","不教臉紅而已。","不知橫亙到何處。","丙可憐似的說。","也須為著子孫鬥爭。","互相提攜走向前去。","亦不算壞。","人類的一分子了。","今夜是明月的良宵。","他正在發瘋呢。","何用自作麻煩。","何須非議。","便把眼皮睜開。","兩方就各答應了。","再鬧一回亦好。","分辨出浩蕩的溪聲。","卻自奉行唯謹。","又一人說。","和他們做新過年。","和鍛鍊團結力。","因為不高興了。","在表示著歡迎。","在閃爍地放亮。","地方領導人。","坐著閒談。","多有一百倍以上。","奏起悲壯的進行曲。","嬉嬉譁譁地跑去了。","將要千圓。","導發反抗力的火戰。","就再開始。","就和解去。","就在明后兩天。","就是金錢。","已像將到黎明之前。","已無暇計較。","忘卻了一切。","怎麼就十五年了。","愈會碰著痛苦。","我去拿一面鑼來。","捲下中街去。","是算不上什麼。","有些多事的人問。","有人詰責似的問。","本來是橫逆不過的。","本該挨罵。","漏射到地上。","為著前進而前進。","甲哈哈地笑著說。","甲總不平地罵。","看看又要到了。","眼睛已失了作用。","神所厭棄本無價值。","移動自己的腳步。","終也渡過彼岸。","終是不可解的疑問。","繞來穿去。","繼續他們的行程。","老人懷疑地問。","街上實在繁榮極了。","街上的孩子們在喊。","被逐的前人之子。","說得很高興似的。","這原因就不容妄測。","運行了一個週環。","那就....。","那痛苦就更難堪了。","那邊比較鬧熱。","險些兒跌倒。","黃金難買少年心。","下了10顆。","也可以回答不喜歡。","以及麻醉劑。","以後再也不亂玩了。","以後少喝咖啡。","你喜歡就都給你。","出門買咖啡。","去煮水餃。","台北市信義區2級。","咖啡早冷了。","咖啡要做我老友。","喝杯咖啡。","好幾個月了。","就是很需要咖啡因。","就是戒不掉。","就會想過去喝一杯。","很好判斷一個人。","心情真的很差。","恩～不賴。","感覺挺傻的。","所幸暫無災情傳出。","早餐機投入使用。","暫時的時空靜止。","最適合中國人。","會讓我撐到幾時。","有死傷…QQ。","水☆餃☆子。","煮水餃ing。","真的很有用。","短褲短袖。","等一個人咖啡。","胃又疼了。","要開始了。","都有可能。","雪可屋的特調咖啡。","頂部放上奶油。"],["一樣是歹命人！","但是這一番啊！","來--來！","來和他們一拚！","值得說什麼爭麵皮！","兄弟們來！","到城裡去啊！","又受了他們一頓罵！","和他們一拚！","實在想不到！","憑這一身！","憑這雙腕！","我要頂禮他啊！","把我們龍頭割去！","捨此一身和他一拚！","明夜沒得再看啦！","歲月真容易過！","比狗還輸！","無目的地前進！","甘失掉了麵皮！","盲目地前進！","老不死的混蛋！","趕快走下山去！","這是如何地悲悽！","這是如何的決意！","那纔利害啦！","也不上你的甜！","幫忙打掃整理家裡！","我的爸媽！","是鬧哪樣啊！","有沒有人要揪團！","有點疲憊！","真的太好吃了啦！","葡萄柚最棒了！","２２８運去台中！"]]

    def zh_lorem_word(replacement = nil)
      zh_lorem_words(1, replacement)
    end

    def zh_lorem_words(total, replacement = nil)
      s = []
      while (s.length < total)
        x = random_one(SENTENCES[ rand(3) ])
        s << random_one(x.split(//u)[0..-2])
      end
      return s.join("")
    end

    def zh_lorem_sentence(replacement = nil)
      if replacement
        return replacement
      end

      out = ""
      while(rand(2) == 1)
        out += random_one(SENTENCES[0])
      end
      out += random_one(SENTENCES[1+rand(2)])
    end


    def zh_lorem_sentences(total, replacement = nil)
      out = ""
      (1..total).map { zh_lorem_sentence(replacement) }.join("")
    end

    def zh_lorem_paragraph(replacement = nil)
      if replacement
        return replacement
      end

      return zh_lorem_paragraphs(1, replacement)
    end

    def zh_lorem_paragraphs(total, replacement = nil)
      if replacement
        return replacement
      end

      (1..total).map do
        zh_lorem_sentences(random_one(3..7), replacement)
      end.join("\n\n")
    end

    private

    def random_one(arr)
      return arr.to_a[ rand(arr.to_a.size) ]
    end
  end

  #from https://github.com/miau715/jp-lorem-helpers-demo/blob/master/view_helpers.rb
  #forked from https://github.com/gugod/zh-lorem/blob/master/lib/zh-lorem.rb
  module JpLoremHelpers
    def jp_lorem_name(replacement = nil)
      if replacement
        replacement
      else
        jp_lorem_last_name + jp_lorem_first_name
      end
    end

    def jp_lorem_name_en(replacement = nil)
      if replacement
        return replacement
      end

      return jp_lorem_first_name_en + " " + jp_lorem_last_name_en
    end

    def jp_lorem_first_name(replacement = nil)
      if replacement
        return replacement
      end

      x = %w[明 久美子 聖人 愛子 昭夫 明日香 大地 綾子 大輔 千夏 五郎 恵美 八郎 春 陽生 陽子 陽斗 悦子 隼人 光 英明 陽菜 秀樹 仁美 輝 星子 一郎 蛍 宏 博子 勇 泉 二郎 純子 潤 香織 堅 霞 海斗 薫 和夫 和枝 和樹 敬子 健一 清子 賢治 喜久子 浩太 京子 誠 舞 勝 真美 正雄 惠 直樹 澪 信孝 美咲 信夫 森子 修 奈々 陸 直美 涼 蘭 良一 玲子 亮太 典子 蓮 早希 龍 里美 龍太郎 幸子 新一 小百合 忍 詩織 四郎 静香 翔 節子 真 貴子 翔太 澄子 空 富子 巧 智子 智 友美 雄彦 椿 太一 梅 武 良子 吉 陽子 大和 吉江 悠人]
      return x[rand(x.size)]
    end

    def jp_lorem_first_name_en(replacement = nil)
      if replacement
        return replacement
      end
      x = %w[Akira Kumiko Masato Aiko Akio Asuka Daichi Ayako Daisuke Chinatsu Gorou Emi Hachirou Haru Haruki Haruko Haruto Etsuko Hayato Hikari Hideaki Hina Hideki Hitomi Hikaru Hoshiko Ichiro Hotaru Hiroshi Hiroko Isamu Izumi Jirou Junko Jun Kaori Ken Kasumi Kaito Kaoru Kazuo Kazue Kazuki Keiko Kenichi Kiyoko Kenji Kikuko Kouta Kumiko Kyouko Makoto Mai Masaru Mami Masao Megumi Naoki Mio Nobutaka Misaki Nobuo Moriko Osamu Nana Riku Naomi Ryou Ran Ryouichi Reiko Ryouta Noriko Ren Saki Ryuu Satomi Ryuutarou Sachiko Shinnichi Sayuri Shinobu Shiori Shirou Shitsuka Shou Setsuko Shin Takako Syouta Sumiko Sora Tomiko Takumi Tomoko Satoshi Tomomi Takehiko Tsubaki Taichi Ume Takeshi Yoshiko Yoshi Youko Yamato Yoshie Yuuto]

      return x[rand(x.size)]
    end

    def jp_lorem_last_name(replacement = nil)
      if replacement
        return replacement
      end

      x = %w[佐藤 鈴木 小林 渡辺 山本 中村 伊藤 加藤 山田 井上 木村 田村 佐々木 林 村上 梅木 小川 松本 山崎 前田 森下 後藤 池田 近藤 西村 福田 宮本 橋本 河野 東野 東 星野 三沢 三村 遠藤 岡本 浅野 志村 藤田 田島 中島 小野 大野 相葉 上田 柴田 竹内 中山 武田 杉山 新井 白石 石川 赤塚 櫻井 松田 吉永 二宮 坂本 菊地 野村 上野 安倍 品川 前村 竹田 竹本 森田 森山 森 阿部 有吉 藤木 宮崎 青木 石田 伊東 岩本 内村 大杉 尾崎 片山 片岡 加藤 川田 北村 小泉 斎藤 佐野 清水 黒木 高田 高山 田中 徳永 豊田 永井 野口 長谷川 服部 原田 三木 水野 三宅 吉田 吉江 岸田]
      return x[rand(x.size)]
    end

    def jp_lorem_last_name_en(replacement = nil)
      if replacement
        return replacement
      end

      x = %w[Satou Suzuki Kobayashi Watanabe Yamamoto Nakamura Ito Katou Yamada Inoue Kimura Tamura Sasaki Hayashi Murakami Umeki Ogawa Matsumoto Yamazaki Maeda Morishita Goto Ikeda Kondo Nishimura Hukuda Miyamoto Hashimoto Kawano Higashino Higashi Hoshino Miyazawa Mimura Endou Okamoto Asano Shimura Fujita Tashima Nakashima Ono Ohno Aiba Ueda Shibata Takeuchi Nakayama Takeda Sugiyama Arai Shiraishi Ishigawa Akatsuka Sakurai Matsuta Yoshinaga Ninomiya Sakamoto Kikuchi Nomura Ueno Abe Shinagawa Maemura Takeda Takemoto Morita Moriyama Mori Ariyoshi Fujiki Miyazaki Aoki Ishida Iwamoto Uchimura Osugi Ozaki Katayama Kataoka Katou Kawada Kitamura Koitsumi Saito Sano Shimizu Kuroki Takada Takayama Tanaka Tokunaga Toyota Nagai Noguchi Hasegawa Hattori Harada Miki Mizuno Miyake Yoshida Yoshie Kishida]
      return x[rand(x.size)]
    end

    def jp_lorem_email(replacement = nil)
      if replacement
        return replacement
      end

      delimiters = [ '_', '-', '' ]
      domains = %w(gmail.com yahoo.co.jp hotmail.com mac.com example.com mail.goo.ne.jp excite.co.jp @chan.ne.jp)
      username = jp_lorem_first_name_en + jp_lorem_last_name_en
      return "#{username}@#{domains[rand(domains.size)]}".downcase
    end

    SENTENCES = [["あるおじいさんが、","子供が言った、","夜になると、","新年に来ると、","冷たい水一杯、","一晩の消費金額、","ある女性は言った、","時は金なり、","一年の設定、","見物人は、","付き合いの礼儀、","時には涼しい秋風のように、","少しの霜ならば、","片側に行列が、","呼ぶの声が、","シルバームーン、","そんな感じの詩を、","午後の談判、","誰も問わず、","もう何も怖くない、","人は流れて、","簡単にはできない、","管理委員は、","何十万円を使って、","目的もわからない、","創造者を知らず、","この機を逃してはならぬ、","探す必要ない、","お兄さんは、","何時間かかるかわからない、","言ったことが分からなくて、","こっそりに、","恐ろしくない、","成功できず、","早く帰らないと、","出世のチャンスは、","どんなレベルの人、","星の光を、","彼を追い込まない、","危険と遭遇しない、","適当に芝居して、","他の人を考えない、","また暇なときは、","お茶を飲んで、","それに答えて、","驚いて聞いた、","感動して話した、","ついに話した、","方向も知らず、","地面も凸凹ですから、","だから簡単じゃなくて、","だから安くなって、","だから余計に焦って、","継母に愛されない、","これも難しくて、","経験も足りないし、","カレンダーを、","高低差がありすぎて、","お互いに信頼して、","お互い支えて、","お互いに助け合い、","皆んな出かけて、","人は認めない、","人は自惚れて、","どうやって心を癒して、","人の信仰は、","どんな様子も、","他の人と話せない、","休暇取りたくない、","二人中の一人は、","そして手を繋いで、","何を感じて、","歩む道が違っても、","二人は疲れて、","人材を採用しなくて、","普段の時は、","ちゃんと土下座して、","あの人の妻は、","その人は気が狂って、","そんな頑張ったのに、","本当に楽しい時は、","心から嬉しく、","叱っても怒らない、","少し遅くので、","皆さんに報告して、","お出かけらしい、","機会を利用して、","でも今の時代は、","それは世の流れで、","熊本に住んでいる人は、","なぜ世の中には、","誰にも感動を伝えられなくて、","労働者たちを、","粉になって、","金をもったいない、","そんな卑怯な人は、","何があっても、","勉強の名を乗って、","仕事をやっている人は、","ちょっと休んで、","世界に広げて、","日本の未来みたい、","そんなにふざけて、","そんな時兄弟は、","前と後と、","そこに光があって、","全部出して、","服を売って、","現実に元って、","無茶苦茶にすると、","他の所はどんな感じ、","外で遊びに行って、","足が刺さって、","市長はそう言って、","春風を吹いて、","世界を囲って、","十五年前、","興奮してはいけない、","自分は満足していて、","喜びはできない、","ある人は喋って、","女たちは、","”私たちの所で、","ただ進んでいて、","誇るものは、","前進だけ、","風の匂いは、","子どもだけ残して、","魔力を貸して、","自分が指を指して、","一位を争って、","同じ地球の上に、","顔の方向に向いて、","無理矢理に、","悲しみを、","残し一日は、","と犬の吠え声、","と無邪気な子どもたち、","と道の街灯、","城の争い、","みんな集まって、","中身は子供ので、"," 真っ黒ですから、","街は賑やかですから、","新年ですので、","影ですので、","親戚から聞いたから、","円に座って、","ある夜は、","リビングの中に、","私を誘って、","こんな社会に、","どんな思っても、","年上にとって、","静かな街で、","寒い風の中に、","同じ遭遇にあって、","何千年前には、","たくさん人の中、","私の思いのなかに、","私の知識の中に、","煙の中に、","太陽をグルグル回って、","こんな時に、","そんな黒い中、","血祭壇の上に、","闇の中、","こんな統治のやり方は、","地方自治の権力は、","地球は太陽を回っていて、","混雑した賑やかな街に","天体現象ですが、","妻を失った彼には、","どんなに正しいことを考えても、","雷の声を聞いて、","仏祖の力を借りて、","子供の答えは、","子供は指示を誤解して、","子供たちの事を考えて、","子供たちは嘘をついて、","子供らしい考え方、","子供らしい目の輝き、","完全に取り消し、","ぜんぜん違う日に、","金持ちは借金して、","それもおかしくない、","本当にかわいそうな人、","頭の中から出して、","怠惰な彼と、","なくした青春、","名前を呼びつづ、","金を貰えて、","学者ぶる人は、","だんだん大きくなって、","何も関係なく、","なんと試合を始めたらしい、","もう成功できない、","器材を準備して、","金も無くすし、","いい家庭を作って、","普段は本が読みたいので、","お店の前の看板では、","得意な口を開いて、","強い肉体を与えて、","新しい刺激への出会いは、","心が恐ろしい、","パスワードを忘れて、","君が僕を忘れても、","楽しくて追い込んで、","彼女を殺した理由は、","突然目が回って、","みんな忘れるのは、","思いもだんだん薄くなって、","もう一つちょっとだけ気になったことは、","今回の出張公演では、","足が疲れたので、","金稼ぐは上手に、","楽な生活か、","金の重要性が増している、","意外に生き残っている、","ゆっくり話して、","私の体験だと、","私がわからないのは、","こういう商品を、","少なくとも、","こんな環境に、","私は子供の時から、","私の意見は","昨日みたい、","心配してません、","だからうちには、","貧乏人には、","だから今回は、","あっちの街は、","全て全部、","流れ星を見て、","リベンジはいらない、","何度でもあきらめずに、","手をポケットに突っこんで、","信用できない、","効果を発揮しないようで、","この年齢までは、","自然乾燥させたり、"," 誠意をこめて、","次には、","紛争のある地域であり、","権威を失って、","そうなると、","強い拳はできない、","茶碗を下ろして、","そして息を軽く吐き出して、","地平線以外、","一番感動したのは、","新年の一日も、","今年は何はともあれ、","理由は色々あれど、","去年の夏、","早く解決して、","正月の期間、","友人や親戚のほか、","異議を却下して、","怒るのは、","喧嘩するのは、","この発言を受けて、","暗い夜、","時間の流れに関しては、","暗い空気、","子どもたちと出会い、","学校で演奏する機会が多く、","教員を目指し､","歴史遺産、","その環境の仲で、","それぞれの場所から、","陽だまりの中、","さよならの手紙書いて、","思い出の場所に、","橋は壊れたので、","あの絵からでは、","鴨の気持ちは、","小さい頃と比べると、","上様はたまに、","そのような年が見えない、","波みたいな雲、","噂によると、","こういう年回りには、","自然に対して、","でも同時に、","以上の様に、","一見難しそうですが、","あんこう鍋、","やっぱり定番は、","何といっても、","コーヒーの本場といえば、","覚悟しかない、","そして僕には、","退屈な町に、","一瞬のうちに、","限界がきてしまったその時、","抗議行動の中、","責任を取らず、","まさかとは思いますが、","以前から、","世界中の旅行者からの、","失敗しない為に、","新築マンションを購入し、","援助はしない、","コペルニクスが生まれた前に、","10数年前に聞いた音楽、","聞いた噂などで、","赤い血が出て、","記者会見の際、","邪魔な石は残らず取り除く、","大気汚染状況について、","礼儀正しい人は、","ブログの記事、","現役大学生とか、","ツイッターで質問すると、","答えていて、","漢字に変換しないので、","私の友達にも、"," 昔は携帯も無いし、","私の一生は、","一年に一回しかありませんが、","私を育ててくれた父は一人で、","私の経験したような状況では、","全部遮断して、","前にも何回か言ってるけど、","思いっきりぶつけて、","そうしないと、","インフルエンザ患者は、","国立感染症研究所の推計では、","新旧両方使用可能だが、","周辺の田んぼは、","風の強い日は、","台風の後、","主人の実家は農家なので、","買ってきて来てくれたのに、","お宅が大丈夫という前提ですが、","責任を含むということであれば、","それでもなお、","先日、","最近読んだ本、","私の人生を大きく変えた1冊、","やっぱり賑やかだな、","何がなんだが、","先生に聞いてみたら、","こんにちは、","この携帯は、","意味が全然わからなかったので、","もう一つの利点として、","資金を手元に残すことができ、","免責事項について、","深夜利用できるレストラン、","人材育成等については、","学校や職場で、","背が高いですけど、","一番後ろのやつは、","日本人は保守的だから、","みんなでごはんを食べたり、","楽しいはずの忘年会ですが、","普通の人ならば、","生きているということは、","かわいくない服を着て、","学生時代の時に、","断固反対の人もいれば、","もう辞めてほしい、","この書き込みは、","いじめられたんですけど、","もしかして、","結論知らずに、","リーダーを目指す、","たしかに、","私が不安そうに、","私が苦しんでいるときは、","個人的には、","ご挨拶が遅れましたが、","年明け一発目、","昨年より、","美の秘訣は、","毎日の軽い筋トレ、","自分のこの手で、","自分のためにあり、","怖くなって、","皆は声を揃えて、","こんなことがあるなんて、","このとき、","友人にメールしたが、","奥さんとはもう別居状態で、","私は今まで、","もちろん、","あなたは、","浮気が発覚してから、","初心者の方まで、","運動不足を解消したい方、","予約制、","病院に行った時には、","朝七時、"],["どうですか？","思い出しながら書いていきます。","エラーが発生するかもしれません。","たくさんいい話しを聞いてきました。","全国に運び出す必要がどこにあるのか？","予約できる飲食店ありませんか？","いかがでしょうか？","家族にがんの人はいませんか？","あと5センチ高かったらなぁ～","それは子どものころから…？","でも僕はよく知りません。","おばさんが店に来ました。","子供にとっては新鮮で面白いものです。","もう人生おしまいだ。","風俗との関連性がとても高いです。","理由がわかりません。","窓を開けてみた。","力強く挨拶をしました。","大丈夫ですかね？","励ましてくれました。","本当に凄く悩みました。","ごめんなさい。","これが自分中心の正体である。","それは不可能なことです。","どちらが選ばれるのか？","我慢せずに言い合いました。","走って家に帰りました。","旦那と喧嘩になりました。","不倫相手と一緒に暮らしてます。","禁酒出来ました。","死に行きます。","うまく使えない。","謎は深まります...。","考えられる原因を教えてください。","息苦しくなったりします。","色々と大変なこともあります。","仕事をしようと思った理由は？","たくさん教えていただきました。","みんなで楽しく踊りました。","水曜日の夜に行っています。","よく褒められます。","人生は忍耐だと思います。","今は気持ちいいです。","餃子70個食べました。","とても心地よいです。","豚足ラーメン。","コーヒーがビックリするほど不味かった。","苦いコーヒー一口飲む。","体に優しいコーヒーですね。","バナナが大好き。","特に何も触れませんでした。","食欲が落ち着きます。","意外と簡単です。","声をかけてきた。","不審者と勘違いする。","完全に忘れた。","いないわけですよ。","働いて帰宅。","反発します。","証明できない。","思わずパチリ。","お弁当も載せてます。","酔っ払ってしまった。","バナナにチョコレートを塗した菓子。","酒に飲まれる癖がある。","何も考えていません。","バナナ公式HP開設。","暴言を吐いたことがある。","こういうのもいいね。","普通ですよ。","メロンパン焼きました。","すごくよかったです。","袋ラーメンでも食うか？","腹減った〜","やはり時間には逆らえない。","サイコー。","以前よりエロくなった。","敵に触れてしまう。","主人公が死ぬパターン。","歯痛は安定してます。","働けていません。","全て断られました。","うつ病を患っています。","一人で戦います。","ゴジラが来ました。","エコモードです。","目を合いました。","思わず笑ってしまった。","もう一杯お願いします。","食べ過ぎてしまう傾向にありました。","バナナ大学。","頑張って下さい。","寝る時は必ず一緒です。","遊んだりしています。","修得しました。","お店を開くのが夢です。","新米主婦です。","非常に重要です。","使用許可を受けた時間以外の使用はできません。","異変すぎる。","少々お待ちください。","という感じはします。","千円になります。","意外と使ってない。","東北在住の20代です。","放映されています。","祈るばかりだ。","曲げて伸ばしてです。","已像將到黎明之前。","農業を研究しよう。","気分の浮沈が激しい人。","塵も積もれば山となる。","ご紹介しています。","ランチがお得。","投稿した外観の写真です。","直営店です。","冷凍みかん。","さっそく使おう。","便利だった。","着る毛布で着ぐるみ生活。","妖精になるのかな？","あぶないと指摘した。","彼女は涙をぬぐった。","誇りに思うわ。","まとめて欲しい。","動けないでしょうが？","私は筋肉大好きです。","お邪魔したくなりました。","整理整頓ができない。","ずーっと降り続けました。","洗濯ものが乾かない時期になってきました。","雲の多い晴れ。","十年早いよ。","俺は酒場に来ていた。","今すぐチェックをしよう。","只今話題沸騰中です。","全額返品保証。","当日お届け可能です。","いつでもお安く。","それは....。","パワーを持っています。","そうそう見つかりません。","もはや熱帯。","羞恥心を買って来い。","充実した一日でした。","麻酔銃で捕まえた。","油断ができない。","まとめてみました。","宜しければどうぞ。","残念な結果でした。","薬のせいなのかな？","ダメでした。","試してみたのですか？","こだわりがあった。","印象も微妙に違う。","実は違いました。","強い訳です。","何が起きたのかも分からない。","判断しやすいですね。","本当にがかり...。","猫を飼いたいのです。","うん〜いいね。","バカバカしい。","本格的な夏到来ですね。","まだまだ梅雨の時期。","ちょっと苦い大人の味〜","天気が変わります。","いつまで我慢できますか？","犠牲者３名を公表した。","水☆餃☆子。","クッキングしています。","とても役立ちました。","座席指定ができないことがあります。","二度とさせない。","お腹が痛い。","グループに設定してます。","どっちも可能ですよ。","対処方法をご案内します。","飛騨牛乳のバターを贅沢に使用しました。"],["なんなんだよあのオヤジは！","胡散臭いもの多すぎワロタ！","俺は諦めないぞ！","とても辛いぞ！","最低だぁ！","変態だー！","出で来いや！","これが効くね！","可哀想すぎですね！","目標達成しました！","ばんざーい！","そうだったのね！","それなら許す！","ほんとに嬉しいです！","本当に奇跡だね！","現在奮闘中！","勝手に発表します！","心配しないで！","この方法お勧めです！","がんばっぺし！","命をかけてやろう！","だから面白い！","そして結論知らずの大激論！","配信初めだぞ！","良い加減にしなさい！","マジで老害だ！","賛成の人も反対の人も意見を出そう！","悲しすぎでしょう！","こんな名言を残した！","レベル高い！","びっくりしました！","意味不明！","絶対に無理だろ！","可愛い～たまら～ん！","そんな風に思う相手がいるなら必見！","疲れました！","ホンマに美味しすぎた！","グレープフルーツは最高だぁ！","我々は納得できない！"]]

    def jp_lorem_word(replacement = nil)
      jp_lorem_words(1, replacement)
    end

    def jp_lorem_words(total, replacement = nil)
      s = []
      while (s.length < total)
        x = random_one(SENTENCES[ rand(3) ])
        s << random_one(x.split(//u)[0..-2])
      end
      return s.join("")
    end

    def jp_lorem_sentence(replacement = nil)
      if replacement
        return replacement
      end

      out = ""
      while(rand(2) == 1)
        out += random_one(SENTENCES[0])
      end
      out += random_one(SENTENCES[1+rand(2)])
    end


    def jp_lorem_sentences(total, replacement = nil)
      out = ""
      (1..total).map { jp_lorem_sentence(replacement) }.join("")
    end

    def jp_lorem_paragraph(replacement = nil)
      if replacement
        return replacement
      end

      return jp_lorem_paragraphs(1, replacement)
    end

    def jp_lorem_paragraphs(total, replacement = nil)
      if replacement
        return replacement
      end

      (1..total).map do
        jp_lorem_sentences(random_one(3..7), replacement)
      end.join("\n\n")
    end

    private

    def random_one(arr)
      return arr.to_a[ rand(arr.to_a.size) ]
    end
  end

  module ViewHelpers #:nodoc:
    include EscapeHelpers
    include ContentHelpers
    include FlashHelpers
    include ParamHelpers
    include RenderHelpers
    include TagHelpers
    include LoremHelpers
    include ZhLoremHelpers
    include JpLoremHelpers
  end
end
