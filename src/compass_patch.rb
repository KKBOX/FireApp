module Compass

  # for add fireapp_build_path configuration property
  module Configuration
    def self.strip_trailing_separator(*args)
      Data.strip_trailing_separator(*args)
    end

    class Watch
      def match?(changed_path)
        if org.jruby.platform.Platform::IS_WINDOWS
          changed_path.gsub!("\\","/")
        end
        
        File.fnmatch(full_glob, changed_path, File::FNM_PATHNAME)
      end
    end
  end

  # add fireapp_build_path configuration property
  Configuration.add_configuration_property(:fireapp_build_path, nil) do
    nil
  end

  #-- coffeescript --
  Configuration.add_configuration_property(:fireapp_coffeescripts_dir, nil) do
    "coffeescripts"
  end
  Configuration.add_configuration_property(:fireapp_coffeescript_options, nil) do
    {}
  end

  #-- livescript --
  Configuration.add_configuration_property(:fireapp_livescripts_dir, nil) do
    "livescripts"
  end
  Configuration.add_configuration_property(:fireapp_livescript_options, nil) do
    {}
  end

  #-- less --
  Configuration.add_configuration_property(:fireapp_less_dir, nil) do
    "less"
  end
  Configuration.add_configuration_property(:fireapp_less_options, nil) do
    {
      :yuicompress => false,
      :verbose => false,
      :color => true,
      :ieCompat => true,
      :strictImports => false,
      :strictMath => false,
      :strictUnits => false
    }
  end
 
  #-- the hold --
  Configuration.add_configuration_property(:the_hold_options, nil) do
    { }
  end

  #-- build --
  Configuration.add_configuration_property(:fireapp_minifyjs_on_build, nil) do
    false
  end  
 
  Configuration.add_configuration_property(:fireapp_always_report_on_build, nil) do
    true
  end
 
  Configuration.add_configuration_property(:fireapp_disable_linecomments_and_debuginfo_on_build, nil) do
    true
  end

  Configuration.add_configuration_property(:fireapp_before_build, nil) do
    nil
  end
  
  Configuration.add_configuration_property(:fireapp_after_build, nil) do
    nil
  end

  # default sass_options is nil
  Configuration.add_configuration_property(:sass_options, nil) do
    {}
  end 

  module Frameworks
    def register_directory(directory)
      loaders = [
        File.join(directory, "compass_init.rb"),
        File.join(directory, 'lib', File.basename(directory)+".rb"),
        File.join(directory, File.basename(directory)+".rb")
      ]
      loader = loaders.detect{|l| File.exists?(l)}
      registered_framework = detect_registration do
        load loader if loader # force reload file, to make sure framework registered
      end
      unless registered_framework
        register File.basename(directory), directory
      end
    end
  end

  class Logger
    def initialize(*actions)
      self.options = actions.last.is_a?(Hash) ? actions.pop : {}
      @display   = self.options[:display]
      @log_dir = self.options[:log_dir] 
      @actions = DEFAULT_ACTIONS.dup
      @actions += actions
    end

    # Record an action that has occurred
    def record(action, *arguments)

      #puts "App::CONFIG['notifications'].include?(action) #{App::CONFIG['notifications'].include?(action)}"
      msg = "#{action_padding(action)}#{action} #{arguments.join(' ')}"
      if App::CONFIG["notifications"].include?(action)
        App.notify( msg.strip, @display )
        @display.wake if @display
      end
      log( msg )
    end

    def emit(msg)
      log(msg)
    end

    def log(msg)
      puts msg
      if App::CONFIG["save_notification_to_file"] && @log_dir
        open(@log_dir + '/fire_app_log.txt','a+') do |f| 
          f.puts Time.now.strftime("%Y-%m-%d %H:%M:%S") + " " + msg
        end
      end
    end
  end

  class Compiler

    # monkey patch for compass issue 
    # https://github.com/chriseppstein/compass/issues/1168
    def css_files
      @css_files = sass_files.map{|sass_file| corresponding_css_file(sass_file)}
    end 

  end
end



if File.exists?( App.shared_extensions_path ) 
  App.scan_library( App.shared_extensions_path )
  Compass::Frameworks.discover( App.shared_extensions_path ) 
end 


