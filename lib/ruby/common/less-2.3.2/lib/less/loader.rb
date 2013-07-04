require 'pathname'
require 'commonjs'
require 'net/http'
require 'uri'

module Less
  class Loader
    
    attr_reader :environment
    
    def initialize
      context_wrapper = Less::JavaScript.context_wrapper.instance
      @context = context_wrapper.unwrap
      @context['process'] = Process.new
      @context['console'] = Console.new
      path = Pathname(__FILE__).dirname.join('js', 'lib')
      @environment = CommonJS::Environment.new(@context, :path => path.to_s)
      @environment.native('path', Path)
      @environment.native('util', Util)
      @environment.native('fs', FS)
      @environment.native('url', Url)
      @environment.native('http', Http)
    end
    
    def require(module_id)
      @environment.require(module_id)
    end
    
    # JS exports (required by less.js) :
    
    class Process # :nodoc:
      def exit(*args)
        warn("JS process.exit(#{args.first}) called from: \n#{caller.join("\n")}")
      end
    end

    class Console # :nodoc:
      def log(*msgs)
        puts msgs.join(', ')
      end
    end
    
    # stubbed JS modules (required by less.js) :
    
    module Path # :nodoc:
      def self.join(*components)
        # node.js expands path on join
        File.expand_path(File.join(*components))
      end

      def self.dirname(path)
        File.dirname(path)
      end

      def self.basename(path)
        File.basename(path)
      end
      
      def self.resolve(path)
        File.basename(path)
      end
      
    end
    
    module Util # :nodoc:
      
      def self.error(*errors)
        raise errors.join(' ')
      end
      
      def self.puts(*args)
        args.each { |arg| STDOUT.puts(arg) }
      end
      
    end

    module FS # :nodoc:
      
      def self.statSync(path)
        File.stat(path)
      end

      def self.readFile(path, encoding, callback)
        callback.call(nil, File.read(path))
      end
      
    end

    module Url # :nodoc:
      
      def self.resolve(*args)
        URI.join(*args)
      end

      def self.parse(url_string)
        u = URI.parse(url_string)
        result = {}
        result['protocol'] = u.scheme  + ':' if u.scheme
        result['hostname'] = u.host if u.host
        result['pathname'] = u.path if u.path
        result['port']     = u.port if u.port
        result['query']    = u.query if u.query
        result['search']   = '?' + u.query if u.query
        result['hash']     = '#' + u.fragment if u.fragment
        result
      end
      
    end
    
    module Http # :nodoc:
      
      def self.get(options, callback)
        err = nil
        begin
          #less always sends options as an object, so no need to check for string
          uri_hash = {}
          uri_hash[:host]     = options['hostname'] ? options['hostname'] : options['host']
          path_components = options['path'] ? options['path'].split('?', 2) : ['']  #have to do this because node expects path and query to be combined
          if path_components.length > 1
            uri_hash[:path]   = path_components[0]
            uri_hash[:query]  = path_components[0]
          else
            uri_hash[:path]   = path_components[0]
          end
          uri_hash[:port]     = options['port'] ? options['port'] : Net::HTTP.http_default_port
          uri_hash[:scheme]   = uri_hash[:port] == Net::HTTP.https_default_port ? 'https' : 'http'  #have to check this way because of node's http.get
          case uri_hash[:scheme]
          when 'http'
            uri = URI::HTTP.build(uri_hash)
          when 'https'
            uri = URI::HTTPS.build(uri_hash)
          else
            raise Exception, 'Less import only supports http and https'
          end
          http = Net::HTTP.new uri.host, uri.port
          if uri.scheme == 'https'
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            http.use_ssl = true
          end
          response = nil
          http.start do |req|
            response = req.get(uri.to_s)
          end
          callback.call ServerResponse.new(response.read_body, response.code.to_i)
        rescue => e
          err = e.message
        ensure
          ret = HttpGetResult.new(err)
        end
        ret
      end
      
      class HttpGetResult
        attr_accessor :err

        def initialize(err)
          @err = err
        end

        def on(event, callback)
          case event
          when 'error'
            callback.call(@err) if @err  #only call when error exists
          else
            callback.call()
          end
        end
      end

      class ServerResponse
        attr_accessor :statusCode
        attr_accessor :data   #faked because ServerResponse acutally implements WriteableStream

        def initialize(data, status_code)
          @data = data
          @statusCode = status_code
        end

        def on(event, callback)
          case event
          when 'data'
            callback.call(@data)
          else
            callback.call()
          end
        end
      end
      
    end
    
  end
end