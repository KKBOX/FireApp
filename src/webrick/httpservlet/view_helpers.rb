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

      sources.map do |source|
        content_tag('script', '', {
          'type' => 'text/javascript',
          'src' => ensure_path(ensure_extension(source, 'js'), 'javascripts')
        }.merge(options))
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

      sources.map do |source|
        tag('link', {
          'rel' => 'stylesheet',
          'type' => 'text/css',
          'media' => 'screen',
          'href' => ensure_path(ensure_extension(source, 'css'), 'stylesheets')
        }.merge(options))
      end.join("\n")
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

    def zh_lorem_word
    end

    def zh_lorem_words
    end

    def zh_lorem_sentence
    end

    def zh_lorem_sentences
    end

    def zh_lorem_paragraph
    end

    def zh_lorem_paragraphs
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
  end
end
