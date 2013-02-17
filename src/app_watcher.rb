
if Compass::VERSION =~ /^0.12/
 $LOAD_PATH.unshift File.join(LIB_PATH,'ruby','compass_0.12','backport_from_0.13','lib')
 require 'compass/watcher'
end

module Compass
  module Watcher
    class  AppWatcher < ProjectWatcher
      def initialize(project_path, watches=[], options={}, poll=false)
        super
        @sass_watchers += coffeescript_watchers
        setup_listener
      end

      def watch!
        compile
        super
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
    end
  end
end
