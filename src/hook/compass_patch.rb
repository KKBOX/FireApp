
require 'after_do'

require 'compass/commands'

# expose listener
class Sass::Plugin::Compiler

  attr_accessor :listener

  m = instance_method("create_listener")
  define_method("create_listener") do |*args, &block| 
    @listener = m.bind(self).(*args, &block)
  end

end

# expose compiler
# - use compiler.listener to get listener
class Compass::SassCompiler
  attr_accessor :compiler # This compiler is Sass::Plugin::Compiler
  
end


# expose compiler
class Compass::Commands::WatchProject

  attr_accessor :sass_compiler # This compiler is Compass::SassCompiler

  m = instance_method("new_compiler_instance")
  define_method("new_compiler_instance") do |*args, &block| 
    @sass_compiler = m.bind(self).(*args, &block)
  end

end

# expose watches
class Compass::Configuration::Data
  def watches=(w)
    @watches = w
  end
end

# run custom compile on update
class Compass::Commands::UpdateProject

  m = instance_method("perform")
  define_method("perform") do |*args, &block| 
    
    if File.exists?( Compass.configuration.fireapp_coffeescripts_dir )
      CoffeeScriptCompiler.compile_folder( Compass.configuration.fireapp_coffeescripts_dir, Compass.configuration.javascripts_dir, Compass.configuration.fireapp_coffeescript_options );
    end
    if File.exists?( Compass.configuration.fireapp_livescripts_dir )
      LiveScriptCompiler.compile_folder( Compass.configuration.fireapp_livescripts_dir, Compass.configuration.javascripts_dir, Compass.configuration.fireapp_livescript_options );
    end
    if File.exists?( Compass.configuration.fireapp_less_dir )
      LessCompiler.compile_folder( Compass.configuration.fireapp_less_dir, Compass.configuration.css_dir, Compass.configuration.fireapp_less_options );
    end

    m.bind(self).(*args, &block)
  end

end

# run custom compile on clean
class Compass::Commands::CleanProject

  m = instance_method("perform")
  define_method("perform") do |*args, &block| 
    
    if File.exists?( Compass.configuration.fireapp_coffeescripts_dir )
      CoffeeScriptCompiler.clean_folder(Compass.configuration.fireapp_coffeescripts_dir, Compass.configuration.javascripts_dir )
    end
    if File.exists?( Compass.configuration.fireapp_livescripts_dir )
      LiveScriptCompiler.clean_folder(Compass.configuration.fireapp_livescripts_dir, Compass.configuration.javascripts_dir )
    end
    if File.exists?( Compass.configuration.fireapp_less_dir )
      LessCompiler.clean_folder(Compass.configuration.fireapp_less_dir, Compass.configuration.css_dir )
    end

    m.bind(self).(*args, &block)
  end

end

Compass::Commands::WatchProject.extend AfterDo
Compass::Commands::WatchProject.after :notify_watches do |modified, added, removed|
  java.lang.System.gc()
end