
require 'livescript'
require 'json'

class LiveScriptCompiler

  def self.log(type, msg)
    msg = msg.sub(File.expand_path(Compass.configuration.project_path), '')[1..-1] if defined?(Tray) 

    if defined?(Tray) && Tray.instance.logger
      Tray.instance.logger.record type, msg
    else  
      puts "   #{type} #{msg}"
    end
  end

  def self.compile_folder( livescripts_dir, javascripts_dir, options={} )
    livescripts_dir = File.expand_path(livescripts_dir)
    javascripts_dir = File.expand_path(javascripts_dir)
    
    Dir.glob( File.join(livescripts_dir, "**", "*.ls")) do |full_path|
      full_path=File.expand_path(full_path)

      new_js_path = get_new_js_path(livescripts_dir, full_path, javascripts_dir)

      LiveScriptCompiler.new(full_path, new_js_path, get_cache_dir(livescripts_dir), options ).compile
    end
  end

  def self.clean_compile_folder( livescripts_dir, javascripts_dir )
    livescripts_dir = File.expand_path(livescripts_dir)
    javascripts_dir = File.expand_path(javascripts_dir)
    
    cache_dir=get_cache_dir(livescripts_dir)
    FileUtils.rm_rf(cache_dir)
    LiveScriptCompiler.log( :remove, "#{cache_dir}/")

    Dir.glob( File.join(livescripts_dir, "**", "*.ls")) do |full_path|
      new_js_path = get_new_js_path(livescripts_dir, full_path, javascripts_dir)
      if File.exists?(new_js_path)
        LiveScriptCompiler.log( :remove, new_js_path)
        FileUtils.rm_rf(new_js_path)
      end 
    end

  end

  def self.get_new_js_path(livescripts_dir, full_path, javascripts_dir)
    full_path=File.expand_path(full_path)
    new_dir  = File.dirname(full_path.to_s.sub(livescripts_dir, ''))
    new_file = File.basename(full_path).gsub(/\.ls/,".js").gsub(/js\.js/,'js')
    return  File.join(javascripts_dir, new_dir, new_file)
  end

  def initialize(livescript_path, javascript_path, cache_dir=nil, options={})
    @livescript_path = Pathname.new(livescript_path)
    @javascript_path   = Pathname.new(javascript_path)
    @cache_dir   = cache_dir ? Pathname.new(cache_dir) : nil
    @compile_options = options
  end

  def compile()
    if @cache_dir
      cache_file = @cache_dir + @livescript_path.to_s.gsub(/[^a-z0-9]/,"_")
      if cache_file.file?
        cache_object = JSON.load( cache_file.read)
        if cache_object["mtime"] == @livescript_path.mtime.to_i
          @js = cache_object["js"]
          write_js_to_file unless @javascript_path.exist?
          return @js
        end
      end

      @js=get_js
      cache_file.open('w') do|f|
        f.write JSON.dump({"mtime" => @livescript_path.mtime.to_i, "js" => @js})
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
      LiveScriptCompiler.log( :overwrite, @javascript_path.to_s)
    else
      LiveScriptCompiler.log( :create, @javascript_path.to_s)
    end
    @javascript_path.open("w"){|f| f.write(@js)}

  end

  def get_js
    begin
      LiveScript.compile @livescript_path.read, @compile_options
    rescue Exception=>e
      error_text = "#{@livescript_path}: #{e.message}"
      LiveScriptCompiler.log( :error, error_text)
      "document.write("+ error_text.to_json + ")"
    end
  end

  def self.get_cache_dir(base_dir)

    if defined?(App) 
      cache_dir = File.expand_path( File.join(Compass.configuration.project_path, ".livescript-cache"))
    else
      cache_dir = File.join( base_dir, ".livescript-cache")
    end

    FileUtils.mkdir_p(cache_dir) unless  File.exists?(cache_dir)
    return cache_dir
  end
end

