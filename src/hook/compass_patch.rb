
require 'after_do'

# module Compass
#   module Commands

#     class WatchProject
#       extend AfterDo


#       def initialize(*p)
#         super

#       end

#     end

#   end
# end

require 'compass/commands'

# exposure listener
class Sass::Plugin::Compiler

  attr_accessor :listener

  m = instance_method("create_listener")
  define_method("create_listener") do |*args, &block| 
    @listener = m.bind(self).(*args, &block)
  end

end

# exposure compiler
# - use compiler.listener to get listener
class Compass::SassCompiler
  attr_accessor :compiler # This compiler is Sass::Plugin::Compiler
  
end


# exposure compiler
class Compass::Commands::WatchProject

  attr_accessor :sass_compiler # This compiler is Compass::SassCompiler

  m = instance_method("new_compiler_instance")
  define_method("new_compiler_instance") do |*args, &block| 
    @sass_compiler = m.bind(self).(*args, &block)
  end

end

# exposure watches
class Compass::Configuration::Data
  def watches=(w)
    @watches = w
  end
end

puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

Compass::Commands::WatchProject.extend AfterDo
Compass::Commands::WatchProject.after :notify_watches do |modified, added, removed|
  java.lang.System.gc()
end