
require 'time'
require 'pathname'
require 'less'
require 'csson'

class LessCompiler

  def self.log(type, msg)
    msg = msg.sub(File.expand_path(Compass.configuration.project_path), '')[1..-1] if defined?(Tray) 

    if defined?(Tray) && Tray.instance.logger
      Tray.instance.logger.record type, msg
    else  
      puts "   #{type} #{msg}"
    end
  end

  def self.compile_folder( less_dir, css_dir, options={} )
    less_dir = File.expand_path(less_dir)
    css_dir = File.expand_path(css_dir)
    
    Dir.glob( File.join(less_dir, "**", "*.less")) do |full_path|
      full_path=File.expand_path(full_path)

      new_css_path = get_new_css_path(less_dir, full_path, css_dir)

      LessCompiler.new(full_path, new_css_path, get_cache_dir(less_dir), options ).compile
    end
  end

  def self.clean_compile_folder( less_dir, css_dir )
    less_dir = File.expand_path(less_dir)
    css_dir = File.expand_path(css_dir)
    
    cache_dir=get_cache_dir(less_dir)
    FileUtils.rm_rf(cache_dir)
    LessCompiler.log( :remove, "#{cache_dir}/")

    Dir.glob( File.join(less_dir, "**", "*.less")) do |full_path|
      new_css_path = get_new_css_path(less_dir, full_path, css_dir)
      if File.exists?(new_css_path)
        LessCompiler.log( :remove, new_css_path)
        FileUtils.rm_rf(new_css_path)
      end 
    end

  end

  def self.get_new_css_path(less_dir, full_path, css_dir)
    full_path=File.expand_path(full_path)
    new_dir  = File.dirname(full_path.to_s.sub(less_dir, ''))
    new_file = File.basename(full_path).gsub(/\.coffee/,".css").gsub(/css\.css/,'css')
    return  File.join(css_dir, new_dir, new_file)
  end

  def initialize(coffeescript_path, javascript_path, cache_dir=nil, options={})
    @coffeescript_path = Pathname.new(coffeescript_path)
    @javascript_path   = Pathname.new(javascript_path)
    @cache_dir   = cache_dir ? Pathname.new(cache_dir) : nil
    @compile_options = options
  end

  def compile()
    if @cache_dir
      cache_file = @cache_dir + @coffeescript_path.to_s.gsub(/[^a-z0-9]/,"_")
      if cache_file.file?
        cache_object = JSON.load( cache_file.read)
        if cache_object["mtime"] == @coffeescript_path.mtime.to_i
          @css = cache_object["css"]
          write_css_to_file unless @javascript_path.exist?
          return @css
        end
      end

      @css=get_css
      cache_file.open('w') do|f|
        f.write JSON.dump({"mtime" => @coffeescript_path.mtime.to_i, "css" => @css})
      end
    else
      @css = get_css
    end

    write_css_to_file
    return @css
  end

  def write_css_to_file
    @javascript_path.parent.mkdir unless @javascript_path.parent.exist?
    if @javascript_path.exist?
      LessCompiler.log( :overwrite, @javascript_path.to_s)
    else
      LessCompiler.log( :create, @javascript_path.to_s)
    end
    @javascript_path.open("w"){|f| f.write(@css)}

  end

  def get_css
    begin
      LessCompiler.compile @coffeescript_path.read, @compile_options
    rescue Exception=>e
      "document.write("+ "#{@coffeescript_path}: #{e.message}".to_csson + ")"
    end
  end

  def self.get_cache_dir(base_dir)

    if defined?(App) 
      cache_dir = File.expand_path( File.join(Compass.configuration.project_path, ".coffeescript-cache"))
    else
      cache_dir = File.join( base_dir, ".coffeescript-cache")
    end

    FileUtils.mkdir_p(cache_dir) unless  File.exists?(cache_dir)
    return cache_dir
  end
end

