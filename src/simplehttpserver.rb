require 'rack'
require 'rack/builder'
require "singleton"
require "webrick"
require 'serve'
require 'slim'
require 'serve/application'
require 'sass'
require 'sass/plugin/rack'
require 'compass'
require 'rack/coffee'

class SimpleHTTPServer
  include Singleton
  def start(dir, options)
    Dir.chdir(dir)
    options={
      :Port => 24681
    }.merge(options)
    
    stop 

    app = Rack::Builder.new do
      Compass.reset_configuration!
      file_name = Compass.detect_configuration_file(dir)
      Compass.add_project_configuration(file_name)

      if File.file?( File.join(dir, "compass.config") ) 
        Compass.add_project_configuration( File.join(dir, "compass.config") )
      end

      Compass.configure_sass_plugin!
      use Sass::Plugin::Rack, nil  # Sass Middleware

      use Rack::CommonLogger
      use Rack::ShowStatus
      use Rack::ShowExceptions
 
      use Rack::Coffee, { 
          :root => 'coffeescripts', 
          :urls => Compass.configuration.http_javascripts_path,
          :cache_compile => true
      }
      views_dir = File.join(dir, 'views')
      public_dir = File.join(dir, 'public')
      puts dir
      if( File.exists?(views_dir) && File.exists?(public_dir))
        run Rack::Cascade.new([
          Serve::RackAdapter.new( views_dir ),
          Rack::Directory.new( public_dir)
        ]) 
      else 
        run Rack::Cascade.new([
          Serve::RackAdapter.new( dir ),
          Rack::Directory.new( dir )
        ]) 
      end
    end

    @webrick_server = Rack::Handler.get('webrick')

    @http_server_thread = Thread.new do 
      @webrick_server.run app, :Port => options[:Port], :Host => "0.0.0.0" do |server|
        trap("INT") { server.shutdown }
      end
    end
  end

  def stop
    @webrick_server.shutdown if @webrick_server
    @webrick_server = nil
    @http_server_thread.kill if @http_server_thread && @http_server_thread.alive?
  end

end

