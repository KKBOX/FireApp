require 'rack'
require 'rack/builder'
require "singleton"
require "webrick"
require 'serve'
require 'slim'
require 'tilt'
require "kramdown"
require 'serve/application'
require 'sass/plugin/rack'
require 'rack/coffee'
require 'haml'
require 'haml/filters'
require 'haml_patch.rb'
class SimpleHTTPServer
  include Singleton
  def start(dir, options)
    Dir.chdir(dir)
    options={
      :Port => 24681
    }.merge(options)

    stop 

    app = Rack::Builder.new do

      use Rack::CommonLogger
      use Rack::ShowStatus
      use Rack::ShowExceptions

      if File.exists?( File.join(Compass.configuration.project_path, 'http_servlet_handler.rb'))
        eval(File.read( File.join(Compass.configuration.project_path, 'http_servlet_handler.rb')))
      end

      views_dir = File.join(dir, 'views')
      public_dir = File.join(dir, 'public')

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
    sleep 1 if org.jruby.platform.Platform::IS_WINDOWS # windows need time to release port end

  end
end
