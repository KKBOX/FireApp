

require 'less_js'
require 'pathname'

class LessCompiler < BaseCompiler

  def self.src_file_ext
    "less"
  end

  def self.dst_file_ext
    "css"
  end

  def self.cache_folder_name
    ".less-cache"
  end

  def self.compile(src_file_path, dst_file_path, options = {})

    self._compile(src_file_path, dst_file_path, options) do 
      LessJs.compile Pathname.new(src_file_path).read, options
    end

  end

end