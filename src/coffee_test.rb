# encoding: utf-8

puts $KCODE
$KCODE = "U"

require 'java'
$LOAD_PATH << 'src'
require 'pathname'

#require 'net/http/post/multipart'

resources_dir =  Pathname.new(__FILE__).dirname().dirname().dirname().to_s()[5..-1]
puts resources_dir
if resources_dir && File.exists?( File.join(resources_dir, 'lib','ruby'))
  LIB_PATH = File.join(resources_dir, 'lib')
else
  LIB_PATH = File.expand_path 'lib' 
end


def scan_library( dir )
    Dir.new( dir ).entries.reject{|e| e =~ /^\./}.each do | subfolder|
      lib_path = File.expand_path( File.join(dir, subfolder,'lib') )
      $LOAD_PATH.unshift( lib_path ) if File.exists?(lib_path)
    end

  end

 common_lib_path = File.join(LIB_PATH, "ruby", "common" )
 scan_library( common_lib_path )

 puts common_lib_path


ENV['PATH'] = File.join(LIB_PATH,'nodejs/osx')+File::PATH_SEPARATOR+ENV['PATH']
ENV["EXECJS_RUNTIME"] = "Node"
require 'coffee-script'
str = "'中文測試'"
puts str
#puts CoffeeScript.compile str



#require "open-uri"
#source = open("http://jashkenas.github.com/coffee-script/extras/coffee-script.js").read


puts ExecJS::Runtimes.names
puts "===="

puts ExecJS::Runtimes.best_available
puts "===="



puts ExecJS::Runtimes.from_environment.name
puts ExecJS.runtime.name


context = ExecJS.compile("function a(t){return '123'+t;}")
puts context.call("a", "中文測試")
