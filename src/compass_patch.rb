module Compass

  # for add fireapp_build_path configuration property
  module Configuration
    def self.strip_trailing_separator(*args)
      Data.strip_trailing_separator(*args)
    end
  end

  # add fireapp_build_path configuration property
  Configuration.add_configuration_property(:fireapp_build_path, nil) do
    nil
  end

  Configuration.add_configuration_property(:fireapp_coffeescripts_dir, nil) do
    "coffeescripts"
  end

  Configuration.add_configuration_property(:fireapp_coffeescript_options, nil) do
    {}
  end
 
  Configuration.add_configuration_property(:the_hold_options, nil) do
    nil
  end

  module Commands
    class UpdateProject
      def perform
        if File.exists?( Compass.configuration.fireapp_coffeescripts_dir )
          CoffeeCompiler.compile_folder( Compass.configuration.fireapp_coffeescripts_dir, Compass.configuration.javascripts_dir, Compass.configuration.fireapp_coffeescript_options );
        end

        compiler = new_compiler_instance
        check_for_sass_files!(compiler)
        compiler.clean! if compiler.new_config?
        error_count = compiler.run
        failed! if error_count > 0 
      end 

    end
    class CleanProject
      def perform
        if File.exists?( Compass.configuration.fireapp_coffeescripts_dir )
          CoffeeCompiler.clean_compile_folder(Compass.configuration.fireapp_coffeescripts_dir, Compass.configuration.javascripts_dir )
        end
        compiler = new_compiler_instance
        compiler.clean!
        Compass::SpriteImporter.find_all_sprite_map_files(Compass.configuration.generated_images_path).each do |sprite|
          remove sprite
        end 
      end 

    end
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

    # Compile one Sass file
    def compile(sass_filename, css_filename)
      start_time = end_time = nil 
      css_content = logger.red do
        timed do
          engine(sass_filename, css_filename).render
        end 
      end 
      duration = options[:time] ? "(#{(css_content.__duration * 1000).round / 1000.0}s)" : ""
      write_file(css_filename, css_content, options.merge(:force => true, :extra => duration))

      Compass.configuration.run_stylesheet_saved(css_filename)

      # PATCH: write wordlist File
      sass_filename_str = sass_filename.gsub(/[^a-z0-9]/i, '_')
      File.open( File.join( App::AUTOCOMPLTETE_CACHE_DIR, sass_filename_str + "_project" ), 'w' ) do |f|
        f.write Compass.configuration.project_path
      end

      if ::Sass::Tree::MixinDefNode.mixins
        File.open( File.join( App::AUTOCOMPLTETE_CACHE_DIR, sass_filename_str + "_mixin" ), 'w' ) do |f|

          ::Sass::Tree::MixinDefNode.mixins.uniq.sort.each do |name|
            f.puts "\"#{name}\""
          end
        end
      end

      if  ::Sass::Tree::VariableNode.variables
        File.open( File.join( App::AUTOCOMPLTETE_CACHE_DIR, sass_filename_str + "_variable" ), 'w' ) do |f|
          ::Sass::Tree::VariableNode.variables.uniq.sort.each do |name|
            f.puts "\"$#{name}\""
          end
        end
      end
    end 
  end
end



if File.exists?( App.shared_extensions_path ) 
  App.scan_library( App.shared_extensions_path )
  Compass::Frameworks.discover( App.shared_extensions_path ) 
end 


