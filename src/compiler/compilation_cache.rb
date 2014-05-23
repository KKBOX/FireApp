
require 'time'
require 'fileutils'
require 'pathname'

class CompilationCache

  def initialize(cache_folder_name)
    if not defined?(App)
      raise "You shoulod have App"
    end

    @project_dir = Pathname.new( Compass.configuration.project_path )
    @cache_dir = File.expand_path( File.join(@project_dir, cache_folder_name))
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

    rel_file_name = Pathname.new(file_name).relative_path_from(@project_dir)
    cache_file.open('w') do |f|
      f.write JSON.dump({
        "mtime" => cache_file.mtime.to_i, 
        "content" => content, 
        "file_path" => rel_file_name.to_s
      })
    end
  end

  def clear
    FileUtils.rm_rf(@cache_dir)
    FileUtils.mkdir_p(@cache_dir) unless File.exists?(@cache_dir)
  end

  def cached_file_list
    Pathname.new(@cache_dir).children.map do |c|
      JSON.load( c.read )["file_path"]
    end.compact
  end

  private

    def get_cache_file(file_name)
      
      Pathname.new( File.join(@cache_dir, file_name.to_s.gsub(/[^\w]/,"_")))
    end


end