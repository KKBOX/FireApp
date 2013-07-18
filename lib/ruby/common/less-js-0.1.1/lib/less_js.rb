require 'execjs'
require 'less_js/source'
require 'pathname'

module LessJs
  class ParseError < StandardError; end

  module Source

    def self.path
      @path ||= ENV['LESSJS_SOURCE_PATH'] || bundled_path
    end

    def self.path=(path)
      @contents = @version = @context = nil
      @path = path
    end

    def self.jsdom_path
      @jsdom_path ||= Pathname.new(__FILE__).join("..", "..", "vender", "node_modules", "jsdom").realpath.to_s
    end

    def self.jsdom_path=(path)
      @jsdom_path = path
    end

    def self.contents
      @contents ||= File.read(path)
    end

    def self.version
      @version ||= contents[/LESS - Leaner CSS v([\d.]+)/, 1]
    end

    def self.fixed_contents
      <<-EOS
        var jsdom = require('#{jsdom_path}').jsdom;
        var document = jsdom("<html><body></body></html>");
        var window = document.createWindow();
        var location = {href: "", protocol: "http", host: "", port: ""};
        var less = window.less = {};
        var tree = less.tree = {};
        
        #{contents}

        function compile(data) {
          var result;
          new less.Parser().parse(data, function(error, tree) {
            result = [error, tree.toCSS()];
          });
          return result;
        }
        
      EOS
    end

    def self.context
      #@context ||= ExecJS.compile(fixed_contents)
      @context ||= ExecJS::Runtimes::Node.compile(fixed_contents)
    end
  end

  class << self
    def version
      Source.version
    end

    # Compile a script (String or IO) to CSS.
    def compile(script, options = {})
      script = script.read if script.respond_to?(:read)

      puts script

      error, data = Source.context.call('compile', script)

      puts error, data

      if error
        raise ParseError, error['message']
      else
        data
      end
    end
  end
end
