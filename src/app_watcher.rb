if Compass::VERSION =~ /^0.12/
  $LOAD_PATH.unshift File.join(LIB_PATH,'ruby','compass_0.12','backport_from_0.13','lib')
  require 'compass/watcher'
end

require 'livereload.rb'
module Compass
  module Watcher
    class  AppWatcher < ProjectWatcher
      def initialize(project_path, watches=[], options={}, poll=false)
        super
        @sass_watchers += coffeescript_watchers
        @sass_watchers += livescript_watchers
        @sass_watchers += livereload_watchers
        @sass_watchers += less_watchers
        setup_listener
      end

      def listen_callback(modified_file, added_file, removed_file)
        #log_action(:info, ">>> Listen Callback fired added: #{added_file}, mod: #{modified_file}, rem: #{removed_file}", {})
        action = nil
        action ||= :modified unless modified_file.empty?
        action ||= :added unless added_file.empty?
        action ||= :removed unless removed_file.empty?

        files = modified_file + added_file + removed_file
        # run watchers
        sass_watchers.each do |watcher|
          files.each do |file|
            if watcher.is_a? Array # for compass 0.12 watcher format
              glob,callback = watcher
              callback.call(project_path, file, action) if File.fnmatch(glob, file)
            else
              watcher.run_callback(project_path, file, action) if watcher.match?(file)
            end
          end
        end
        java.lang.System.gc()
      end

      def watch!
        compile
        super
      end
      
      def stop
        log_action(:info, "AppWatcher stop!",{})
        begin
          listener.stop if listener.adapter
        rescue Exception => e
          log_action(:warning, "#{e.message}\n#{e.backtrace}", {})
        end

      end

      def coffeescript_watchers
        coffee_filter = File.join(Compass.configuration.fireapp_coffeescripts_dir,  "*.coffee")
        child_coffee_filter = File.join(Compass.configuration.fireapp_coffeescripts_dir, "**", "*.coffee")

        [ Watcher::Watch.new(child_coffee_filter, &method(:coffee_callback) ),
          Watcher::Watch.new(coffee_filter, &method(:coffee_callback) ) ]
      end

      def coffee_callback(base, file, action)
        log_action(:info, "#{file} was #{action}", options)
        puts( "#{file} was #{action}", options)
        CoffeeCompiler.compile_folder( Compass.configuration.fireapp_coffeescripts_dir,
                                      Compass.configuration.javascripts_dir, 
                                      Compass.configuration.fireapp_coffeescript_options );
      end
      
      def livescript_watchers
        filter = File.join(Compass.configuration.fireapp_livescripts_dir,  "*.ls")
        child_filter = File.join(Compass.configuration.fireapp_livescripts_dir, "**", "*.ls")

        [ Watcher::Watch.new(child_filter, &method(:livescript_callback) ),
          Watcher::Watch.new(filter, &method(:livescript_callback) ) ]
      end

      def livescript_callback(base, file, action)
        log_action(:info, "#{file} was #{action}", options)
        puts( "#{file} was #{action}", options)
        LiveScriptCompiler.compile_folder( Compass.configuration.fireapp_livescripts_dir,
                                      Compass.configuration.javascripts_dir, 
                                      Compass.configuration.fireapp_livescript_options );
      end

      def livereload_watchers
       ::App::CONFIG["services_livereload_extensions"].split(/,/).map do |ext|
         filter = "**.#{ext}"
         Watcher::Watch.new(filter, &method(:livereload_callback)) 
       end
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

      def less_watchers
        filter = File.join(Compass.configuration.fireapp_less_dir,  "*.less")
        child_filter = File.join(Compass.configuration.fireapp_less_dir, "**", "*.less")

        [ Watcher::Watch.new(child_filter, &method(:less_callback) ),
          Watcher::Watch.new(filter, &method(:less_callback) ) ]
      end

      def less_callback(base, file, action)
        log_action(:info, "#{file} was #{action}", options)
        puts( "#{file} was #{action}", options)
        LessCompiler.compile_folder( Compass.configuration.fireapp_less_dir,
                                      Compass.configuration.css_dir, 
                                      Compass.configuration.fireapp_less_options );
      end


      def setup_listener
        @listener = Listen.to(@project_path, :relative_paths => true)
        if poll
          @listener = listener.force_polling(true)
        end 
        @listener = listener.polling_fallback_message(POLLING_MESSAGE)
        #@listener = listener.ignore(/\.css$/) # we dont ignore .css, because we need livereload
        @listener = listener.change(&method(:listen_callback))
      end 

    end
  end
end
