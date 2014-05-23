
require 'time'
require 'fileutils'
require 'pathname'

class CompilationCache

  def initialize(cache_folder_name)
    if not defined?(App)
      raise "You shoulod have App"
    end

    @cache_dir = File.expand_path( File.join(Compass.configuration.project_path, cache_folder_name))
    FileUtils.mkdir_p(@cache_dir) unless  File.exists?(@cache_dir)
  end

  def cache_dir
    @cache_dir
  end

  def get(file_name)
    cache_file = get_cache_file(file_name)
    cache_object = JSON.load( cache_file.read ) if cache_file.file?

    return cache_object["content"] if cache_object && cache_object["mtime"] == file_name.mtime.to_i
    return nil
  end

  def update(file_name, content)
    cache_file = get_cache_file(file_name)
    cache_file.open('w') do|f|
      f.write JSON.dump({"mtime" => cache_file.mtime.to_i, "content" => content})
    end
  end

  def clear
    FileUtils.rm_rf(@cache_dir)
    FileUtils.mkdir_p(@cache_dir) unless  File.exists?(@cache_dir)
  end

  private

    def get_cache_file(file_name)
      Pathname.new( File.join(@cache_dir, file_name.to_s.gsub(/[^a-z0-9]/,"_")) )
    end


end