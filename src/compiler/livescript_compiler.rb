
require 'livescript'
require 'pathname'

class LiveScriptCompiler < BaseCompiler

  def self.src_file_ext
    "ls"
  end

  def self.dst_file_ext
    "js"
  end

  def self.cache_folder_name
    ".livescript-cache"
  end

  def self.compile(src_file_path, dst_file_path, options = {})

    self._compile(src_file_path, dst_file_path, options) do 
      LiveScript.compile Pathname.new(src_file_path).read, options
    end

  end

end