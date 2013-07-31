
require 'time'
require 'pathname'
require 'less_js'
require 'json'

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
    new_file = File.basename(full_path).gsub(/\.less/,".css").gsub(/css\.css/,'css')
    return  File.join(css_dir, new_dir, new_file)
  end

  def initialize(less_path, css_path, cache_dir=nil, options={})
    @less_path = Pathname.new(less_path)
    @css_path   = Pathname.new(css_path)
    @cache_dir   = cache_dir ? Pathname.new(cache_dir) : nil
    @compile_options = {}.merge(options)
  end

  def compile()
    if @cache_dir
      cache_file = @cache_dir + @less_path.to_s.gsub(/[^a-z0-9]/,"_")
      if cache_file.file?
        cache_object = JSON.load( cache_file.read)
        if cache_object["mtime"] == @less_path.mtime.to_i
          @css = cache_object["css"]
          write_css_to_file unless @css_path.exist?
          return @css
        end
      end

      @css = get_css
      cache_file.open('w') do|f|
        f.write JSON.dump({"mtime" => @less_path.mtime.to_i, "css" => @css})
      end
    else
      @css = get_css
    end

    write_css_to_file
    return @css
  end

  def write_css_to_file
    @css_path.parent.mkdir unless @css_path.parent.exist?
    if @css_path.exist?
      LessCompiler.log( :overwrite, @css_path.to_s)
    else
      LessCompiler.log( :create, @css_path.to_s)
    end
    @css_path.open("w"){|f| f.write(@css)}

  end

  def get_css
    begin
      options = @compile_options || {}
      (options["paths"] ||= []) << Compass.configuration.fireapp_less_dir
      LessJs.compile @less_path.read , @compile_options
    rescue Exception=>e
      "document.write("+ "#{@less_path}: #{e.message}".to_json + ")"
    end
  end

  def self.get_cache_dir(base_dir)

    if defined?(App) 
      cache_dir = File.expand_path( File.join(Compass.configuration.project_path, ".less-cache"))
    else
      cache_dir = File.join( base_dir, ".less-cache")
    end

    FileUtils.mkdir_p(cache_dir) unless  File.exists?(cache_dir)
    return cache_dir
  end
end

