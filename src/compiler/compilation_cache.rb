
require 'fileutils'

class CompilationCache

  def initialize
    if not defined?(App)
      raise "You shoulod have App"
    end

    @cache_dir = File.expand_path( File.join(Compass.configuration.project_path, self.cache_folder_name))
    FileUtils.mkdir_p(@cache_dir) unless  File.exists?(@cache_dir)
  end

  

end