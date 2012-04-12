class SimpleHTTPServer
  include Singleton
  include WEBrick
  def start(dir, options)
    unless defined?( WEBrick::HTTPServlet::DynamicHandler )
      require "webrick/httpservlet/dynamic_handler"
      require "webrick/httpservlet/coffeescript_handler"
    end

    if File.exists?( File.join(Compass.configuration.project_path, 'http_servlet_handler.rb'))
      load File.join(Compass.configuration.project_path, 'http_servlet_handler.rb')
    end

    options={
      :Port => 24680
    }.merge(options)
    stop
    @http_server = HTTPServer.new(options) unless @http_server
    @http_server.mount("/#{Compass.configuration.javascripts_dir}", WEBrick::HTTPServlet::CoffeeScriptHandler) 
    @http_server_thread = Thread.new do 
      @http_server.mount("/",HTTPServlet::FileHandler, dir,  {
        :AcceptableLanguages => WEBrick::HTTPServlet::FileHandler::HandlerTable.keys,
        :FancyIndexing => true,
        :MimeTypes => FireAppMimeTypes
      });
      @http_server.start
    end
  end

  def stop
    @http_server.shutdown if @http_server
    @http_server = nil 
    @http_server_thread.kill if @http_server_thread && @http_server_thread.alive?
  end

end

