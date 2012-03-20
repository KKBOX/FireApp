# the logic form https://github.com/jlong/serve/blob/master/lib/serve/handlers/dynamic_handler.rb

require 'tilt'
require 'active_support/all'
require 'rhino'
require 'execjs'
require 'coffee-script'

module WEBrick
  module HTTPServlet
    class CoffeeScriptHandler < AbstractServlet
      def get_instance(server, *options)
        self
      end

      def initialize(server, *options)
        super(server, options) if( server )
      end

      ##
      # Handles GET requests

      def do_GET(req, res)
        begin
          res.body = parse(req, res)
          res['content-type'] ||= "text/javascript"
        rescue StandardError => ex
          raise
        rescue Exception => ex
          @logger.error(ex)
          raise HTTPStatus::InternalServerError, ex.message
        end
      end

      ##
      # Handles POST requests

      alias do_POST do_GET

      private

      def parse(request, response)
        root_path = Compass.configuration.project_path
        script_filename = File.join(root_path, request.path)
        
        coffeescript_filename = script_filename.gsub(/\/#{Compass.configuration.javascripts_dir}\//,"/coffeescripts/").gsub(/\.js$/,".coffee")
        
        if File.exists?(script_filename)
          File.open(script_filename, 'r').read 
        elsif File.exists?(coffeescript_filename)
          Tilt["coffee"].new(coffeescript_filename, nil, :outvar => '_out_buf').render
        else
          raise HTTPStatus::NotFound, "`#{request.path}' not found."
        end
      end


    end

  end
end
