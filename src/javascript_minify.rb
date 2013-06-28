
require 'time'
require 'pathname'
require 'uglifier'
require 'json'

class JavascriptMinify

  def self.log(type, msg)
    msg = msg.sub(File.expand_path(Compass.configuration.project_path), '')[1..-1] if defined?(Tray) 

    if defined?(Tray) && Tray.instance.logger
      Tray.instance.logger.record type, msg
    else  
      puts "Minify: #{type} #{msg}"
    end
  end

  def self.clean_minify_folder(javascripts_min_dir )
    javascripts_min_dir = File.expand_path(javascripts_min_dir)
    FileUtils.rm_rf(javascripts_min_dir)
    JavascriptMinify.log( :remove, "#{javascripts_min_dir}/")
  end

  def self.minify_folder(javascripts_dir, javascripts_min_dir)
    javascripts_dir = File.expand_path(javascripts_dir)

    Dir.glob( File.join(javascripts_dir, "**", "*.js")) do |full_path|
      if full_path.index(".min.js") == nil #no double minification unless specifically set.
        minify_file(full_path, javascripts_dir, javascripts_min_dir)
      end
    end
  end

  def self.minify_file(full_path, javascripts_dir, javascripts_min_dir)

    javascripts_dir = File.expand_path(javascripts_dir)
    javascripts_min_dir = File.expand_path(javascripts_min_dir)

    full_path=File.expand_path(full_path)

    new_js_path = get_new_js_path(full_path, javascripts_dir, javascripts_min_dir)
    
    # If the change is the file being deleted, delete the min.js one.
    if File.exists?(full_path) == false
      FileUtils.rm_rf(new_js_path)
    else
      minify(full_path, new_js_path)
    end

  end

  def self.get_new_js_path(full_path, javascripts_dir, javascripts_min_dir)
    full_path= File.expand_path(full_path)
    new_dir  = File.dirname(full_path.to_s.sub(javascripts_dir, ''))

    if full_path.index(".min.js") == nil #no adding min.min.js
      new_file = File.basename(full_path).gsub(/\.js$/,".min.js")
    else
      new_file = File.basename(full_path)
    end

    return  File.join(javascripts_min_dir, new_dir, new_file)
  end

  def initialize(javascript_path)
      @javascript_path   = Pathname.new(javascript_path)
  end

  def self.minify(full_path, new_js_path)

    FileUtils.mkdir_p(File.dirname(new_js_path)) #make sure the folders exist

    if File.exists?(new_js_path)
      FileUtils.rm_rf(new_js_path)
    end
    File.open(new_js_path, 'w') do |f|
      f.write(Uglifier.compile(File.read(full_path)))
    end
  end
end