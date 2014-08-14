require 'livereload.rb'

class LivereloadWatch < Compass::Configuration::Watch
  def match?(changed_path)
    @glob.split(/,/).each do  |ext|
      changed_path =~ Regexp.new("#{ext}\\Z")
    end
  end
end

class  AppWatcher < Compass::Commands::WatchProject
  def initialize(project_path, options={})
    super

    WatchHooker.watches << livereload_watchers
    #@watchers += livescript_watchers
    #@watchers += coffeescript_watchers
    
    WatchHooker.watches  += custom_watcher(Compass.configuration.fireapp_coffeescripts_dir, "*.coffee", method(:coffee_callback))
    WatchHooker.watches  += custom_watcher(Compass.configuration.fireapp_livescripts_dir, "*.ls", method(:livescript_callback))
    WatchHooker.watches  += custom_watcher(Compass.configuration.fireapp_less_dir, "*.less", method(:less_callback))

  end

  def watch!
    perform
    compiler.compile!
  end
  
  def stop
    listener = compiler.compiler.listener

    log_action(:info, "AppWatcher stop!",{})
    begin
      listener.stop if listener.adapter
    rescue Exception => e
      log_action(:warning, "#{e.message}\n#{e.backtrace}", {})
    end

  end


  def custom_watcher(dir, extensions, callback)
    filter = File.join(dir, extensions)
    childe_filter = File.join(dir, "**", extensions)

    [Compass::Configuration::Watch.new(filter, &callback),
     Compass::Configuration::Watch.new(childe_filter, &callback)]
  end

  def coffee_callback(base, file, action)
    log_action(:info, "#{file} was #{action}", options)
    puts( "#{file} was #{action}", options)
    CoffeeScriptCompiler.compile_folder( Compass.configuration.fireapp_coffeescripts_dir,
                                  Compass.configuration.javascripts_dir, 
                                  Compass.configuration.fireapp_coffeescript_options );
  end

  def livescript_callback(base, file, action)
    log_action(:info, "#{file} was #{action}", options)
    puts( "#{file} was #{action}", options)
    LiveScriptCompiler.compile_folder( Compass.configuration.fireapp_livescripts_dir,
                                  Compass.configuration.javascripts_dir, 
                                  Compass.configuration.fireapp_livescript_options );
  end



  def less_callback(base, file, action)
    log_action(:info, "#{file} was #{action}", options)
    puts( "#{file} was #{action}", options)
    LessCompiler.compile_folder( Compass.configuration.fireapp_less_dir,
                                  Compass.configuration.css_dir, 
                                  Compass.configuration.fireapp_less_options );
  end

  def livereload_watchers
   LivereloadWatch.new(::App::CONFIG["services_livereload_extensions"], &method(:livereload_callback))
  end

  def livereload_callback(base, file, action)
    puts ">>> #{action} detected to: #{file}"
    SimpleLivereload.instance.send_livereload_msg( base, file ) if SimpleLivereload.instance.alive?

    if App::CONFIG["notifications"].include?(:overwrite) && action == :modified
      App.notifications << "Changed: #{file}"
    end

    tray = Tray.instance
    tray.shell.display.wake if tray.shell
  end 


end
