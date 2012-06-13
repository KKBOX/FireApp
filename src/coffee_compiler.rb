require 'time'
require 'pathname'
require 'coffee_script'
require 'json'

class CoffeeCompiler

  def self.log(type, msg)
    msg = msg.gsub(/#{File.expand_path(Compass.configuration.project_path)}/, '')[1..-1] if defined?(Tray) 

    if defined?(Tray) && Tray.instance.logger
      Tray.instance.logger.record type, msg
    else  
      puts "   #{type} #{msg}"
    end
  end

  def self.compile_folder( coffeescripts_dir, javascripts_dir )
    coffeescripts_dir = File.expand_path(coffeescripts_dir)
    javascripts_dir = File.expand_path(javascripts_dir)
    
    Dir.glob( File.join(coffeescripts_dir, "**", "*.coffee")) do |full_path|
      full_path=File.expand_path(full_path)

      new_js_path = get_new_js_path(coffeescripts_dir, full_path, javascripts_dir)

      CoffeeCompiler.new(full_path, new_js_path, get_cache_dir(coffeescripts_dir) ).compile
    end
  end

  def self.clean_compile_folder( coffeescripts_dir, javascripts_dir )
    coffeescripts_dir = File.expand_path(coffeescripts_dir)
    javascripts_dir = File.expand_path(javascripts_dir)
    
    cache_dir=get_cache_dir(coffeescripts_dir)
    FileUtils.rm_r(cache_dir)
    CoffeeCompiler.log( :remove, cache_dir)
    Dir.glob( File.join(coffeescripts_dir, "**", "*.coffee")) do |full_path|
      new_js_path = get_new_js_path(coffeescripts_dir, full_path, javascripts_dir)
      CoffeeCompiler.log( :remove, new_js_path)
      FileUtils.rm(new_js_path)
    end

  end

  def self.get_new_js_path(coffeescripts_dir, full_path, javascripts_dir)
    full_path=File.expand_path(full_path)
    new_dir  = File.dirname(full_path.gsub(/#{coffeescripts_dir}/, ''))
    new_file = File.basename(full_path).gsub(/\.coffee/,".js").gsub(/js\.js/,'js')
    return  File.join(javascripts_dir, new_dir, new_file)
  end

  def initialize(coffeescript_path, javascript_path, cache_dir=nil)
    @coffeescript_path = Pathname.new(coffeescript_path)
    @javascript_path   = Pathname.new(javascript_path)
    @cache_dir   = cache_dir ? Pathname.new(cache_dir) : nil
  end

  def compile()
    if @cache_dir
      cache_file = @cache_dir + @coffeescript_path.to_s.gsub(/[^a-z0-9]/,"_")
      if cache_file.file?
        cache_object = JSON.load( cache_file.read)
        if cache_object["mtime"] == @coffeescript_path.mtime.to_i
          @js = cache_object["js"]
          write_js_to_file unless @javascript_path.exist?
          return @js
        end
      end

      @js=get_js
      cache_file.open('w') do|f|
        f.write JSON.dump({"mtime" => @coffeescript_path.mtime.to_i, "js" => @js})
      end
    else
      @js = get_js
    end

    write_js_to_file
    return @js
  end

  def write_js_to_file
    @javascript_path.parent.mkdir unless @javascript_path.parent.exist?
    if @javascript_path.exist?
      CoffeeCompiler.log( :overwrite, @javascript_path.to_s)
    else
      CoffeeCompiler.log( :create, @javascript_path.to_s)
    end
    @javascript_path.open("w"){|f| f.write(@js)}

  end

  def get_js
    begin
      CoffeeScript.compile @coffeescript_path.read
    rescue Exception=>e
      "document.write("+ "#{@coffeescript_path}: #{e.message}".to_json + ")"
    end
  end

  def self.get_cache_dir(base_dir)
    cache_dir = File.join( base_dir, ".coffeescript_cache")
    FileUtils.mkdir_p(cache_dir) unless  File.exists?(cache_dir)
    return cache_dir
  end
end

