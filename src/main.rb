INITAT=Time.now

$LOAD_PATH << 'src'

ruby_lib_path = File.join(File.dirname(File.dirname(File.dirname(File.dirname(__FILE__)))), "ruby").to_s()[5..-1] 
if File.exists?( ruby_lib_path ) 
  LIB_PATH = File.expand_path File.join(File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))).to_s()[5..-1] 
else 
  LIB_PATH = File.expand_path 'lib' 
end

require "swt_wrapper"
require "ui/splash_window"
SplashWindow.instance.replace('Loading...')
require "require_patch.rb"
require "singleton"
require "webrick";
require 'stringio'
require 'thread'
require "open-uri"
require "yaml"
%w{alert notification quit_window tray preference_panel report welcome_window}.each do | f |
  require "ui/#{f}"
end

require "app.rb"


begin
  App.require_compass
 
  begin
    $LOAD_PATH.unshift('src')
    require 'execjs'
    require "fsevent_patch" if App::OS == 'darwin'
    require "coffee_compiler.rb"
    require "compass_patch.rb"
    require "sass_patch.rb"
  rescue ExecJS::RuntimeUnavailable => e
    raise  "Please install Node.js first\n https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager"
  end

  require 'em-websocket'
  require 'json'

  %w{ninesixty html5-boilerplate compass-h5bp bootstrap-sass susy zurb-foundation fireapp-example}.each do |x|
    begin
      require x
    rescue LoadError
    end
  end

  
  if App::CONFIG['show_welcome']
    WelcomeWindow.new
  end


  App.clear_autocomplete_cache

  Tray.instance.run(:watch => ARGV[0])

rescue Exception => e
  puts e.message
  puts e.backtrace
  App.report( e.message + "\n" + e.backtrace.join("\n"), nil, {:show_reset_button => true} )
  App.display.dispose

end
