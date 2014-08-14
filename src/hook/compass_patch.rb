
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



# exposure listener
class Sass::Plugin::Compiler

  def listener=(l)
    @listener = l
  end

  def listener
    @listener
  end

end




Compass::Commands::WatchProject.extend AfterDo
Compass::Commands::WatchProject.after :notify_watches do |modified, added, removed|

  java.lang.System.gc()
end