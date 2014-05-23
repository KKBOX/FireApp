
require 'coffee_script'
require 'pathname'

class CoffeeScriptCompiler < BaseCompiler

  def self.src_file_ext
    "coffee"
  end

  def self.dst_file_ext
    "js"
  end

  def self.cache_folder_name
    ".coffeescript-cache"
  end

  def self.compile(src_file_path, dst_file_path, options = {})

    self._compile(src_file_path, dst_file_path, options) do 
      CoffeeScript.compile Pathname.new(src_file_path).read, options
    end

  end

end