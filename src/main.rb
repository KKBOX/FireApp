INITAT=Time.now

require 'java'
$LOAD_PATH << File.expand_path("src")

require 'uri'
require 'cgi'
MAIN_FILE_PATH = CGI.unescape(URI.parse(URI.escape(__FILE__)).path)
resources_dir = File.join(File.dirname( File.dirname(File.dirname( MAIN_FILE_PATH ))), 'Resources')
if File.exists?( File.join(resources_dir, 'lib','ruby'))
    LIB_PATH = File.join(resources_dir, 'lib')
else
    LIB_PATH = File.expand_path 'lib'
end

# set execjs runtime
ENV["EXECJS_RUNTIME"] = "Node"

# bundle nodejs for windows so we need add node.exe path to ENV['PATH']
if org.jruby.platform.Platform::IS_WINDOWS
  ENV['PATH'] = File.join(LIB_PATH,'nodejs','win')+File::PATH_SEPARATOR+ENV['PATH']
elsif org.jruby.platform.Platform::IS_MAC
  ENV['PATH'] = File.join(LIB_PATH,'nodejs','osx')+File::PATH_SEPARATOR+ENV['PATH']
elsif org.jruby.platform.Platform::IS_LINUX
  ENV['PATH'] = File.join(LIB_PATH,'nodejs','linux')+File::PATH_SEPARATOR+ENV['PATH']
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
%w{alert notification quit_window tray preference_panel report welcome_window change_options_panel progress_window}.each do | f |
  require "ui/#{f}"
end

require 'tcpsocket-server'



require 'optparse'
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  options[:config_dir] = File.join( java.lang.System.getProperty("user.home") , '.fire-app' )
  opts.on("-c PATH", "--config-dir PATH", "config dir path") do |v|
    options[:config_dir] = v
  end

  options[:watch] = nil
  opts.on("-w PATH", "--watch-dir PATH",  "default watch path") do |v|
    options[:watch_dir] = v
  end

end.parse!

begin
  # TODO: dirty, need refactor
  if File.directory?(File.dirname(options[:config_dir])) && File.writable?(File.dirname(options[:config_dir]))
    CONFIG_DIR = options[:config_dir]
  else
    CONFIG_DIR = File.join(Dir.pwd, 'config')
    Alert.new("Can't Create #{options[:config_dir]}, just put config folder to #{CONFIG_DIR}")
  end

  require "app.rb"
  App.require_compass

  begin
    $LOAD_PATH.unshift('src')
    require 'execjs'
    require "fsevent_patch" if App::OS == 'darwin'
    # require "less_compiler.rb"
    require "app_watcher.rb"
    require "compass_patch.rb"
    require "the_hold_uploader.rb"
    require "project_builder.rb"
    require "notifier"



    %w{compilation_cache base_compiler coffeescript_compiler livescript_compiler less_compiler}.each do | f |
      require "compiler/#{f}"
    end

    %w{compass_patch hook_utils base_compass_hooker watch_hooker}.each do | f |
      require "hook/#{f}"
    end



  rescue ExecJS::RuntimeUnavailable => e
    raise  "Please install Node.js first\n https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager"
  end

  require 'json'

  %w{ninesixty
    html5-boilerplate
    compass-h5bp
    compass-normalize
    bootstrap-sass
    breakpoint
    susy
    zurb-foundation
    fireapp-example}.each do |x|
    begin
      require x
    rescue LoadError
    end
  end


  if App::CONFIG['show_welcome']
    WelcomeWindow.new
  end


  Tray.instance.run(:watch => options[:watch_dir])

rescue Exception => e
  puts e.message
  puts e.backtrace
  Report.new( e.message + "\n" + e.backtrace.join("\n"), nil, {:show_reset_button => true} )
  #App.display.dispose

end
