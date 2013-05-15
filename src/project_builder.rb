
class ProjectBuilder

  attr_reader :project_path

  def self.log(type, msg)
    msg = msg.sub(File.expand_path(Compass.configuration.project_path), '')[1..-1] if defined?(Tray) 

    if defined?(Tray) && Tray.instance.logger
      Tray.instance.logger.record type, msg
    else  
      puts "   #{type} #{msg}"
    end
  end

  def initialize(project_path)
    @project_path = project_path
  end

  def get_black_list(include_tilt_key = false)

    # rebuild sass & coffeescript
    is_compass_project = false
    x = Compass::Commands::UpdateProject.new( @project_path, {})
    if !x.new_compiler_instance.sass_files.empty? # if we rebuild compass project
      x.perform
      is_compass_project = true
    end

    blacklist = []
    build_ignore_file = "build_ignore.txt"

    if File.exists?(File.join( @project_path, build_ignore_file))
      blacklist << build_ignore_file
      blacklist += File.open( File.join( @project_path, build_ignore_file) ).readlines.map{|p|
        p.strip
      }
    else
      blacklist += [
        "*.swp",
        "*.layout",
        "*~",
        "*/.DS_Store",
        "*/.git",
        "*/.gitignore",
        "*.svn",
        "*/Thumbs.db",
        "*/.sass-cache",
        "*/.coffeescript-cache",
        "*/compass_app_log.txt",
        "*/fire_app_log.txt",
        "view_helpers.rb",
        "Gemfile",
        "Gemfile.lock",
        "config.ru"
      ]
      blacklist << File.basename(Compass.detect_configuration_file) if is_compass_project

      Tilt.mappings.each{|key, value| blacklist << "*.#{key}" if !key.strip.empty? } if include_tilt_key

      blacklist
    end



    def build_html(release_dir, blacklist)
      #build html 
      Dir.glob( File.join(@project_path, '**', "[^_]*.*.{#{Tilt.mappings.keys.join(',')}}") ) do |file|
        if file =~ /build_\d{14}/ || file.index(release_dir)
          next 
        end
        extname=File.extname(file)
        if Tilt[ extname[1..-1] ]
          request_path = file[@project_path.length ... (-1*extname.size)]
          pass = false
          blacklist.each do |pattern|
            if File.fnmatch(pattern, request_path[1..-1])
              pass = true
              break
            end
          end
          next if pass

          write_dynamaic_file(release_dir, request_path)
          ProjectBuilder.log("Create", "#{request_path}")
          yield "Create: #{request_path}"
        end
      end
    end

    def build_static_file(release_dir, blacklist)
      #copy static file
      Dir.glob( File.join(@project_path, '**', '*') ) do |file|
        path = file[(@project_path.length+1) .. -1]
        next if path =~ /build_\d{14}/
        
        pass = false
        blacklist.each do |pattern|
          puts path,pattern if path =~ /proxy/
            if File.fnmatch(pattern, path)
              pass = true
              break
            end
        end
        next if pass

        new_file = File.join(release_dir, path)
        if File.file? file
          FileUtils.mkdir_p( File.dirname(  new_file ))

          if File.extname(file) == '.js' && Compass.configuration.fireapp_minifyjs_on_build then
            
            begin
              File.open(new_file, 'w') do |f|
                require 'uglifier'
                f.write(Uglifier.compile(File.read(file)))
              end
              ProjectBuilder.log("Minify", "##{file.gsub(/#{@project_path}/,'')}")
              yield "Minify: #{file.gsub(/#{@project_path}/,'')}"
            rescue Exception => e
              FileUtils.cp( file, new_file )
              ProjectBuilder.log("! Minify", "##{file.gsub(/#{@project_path}/,'')} Fail, Please check")
              yield "! Minify: #{file.gsub(/#{@project_path}/,'')} Fail, Please check"
            end
          elsif
            FileUtils.cp( file, new_file )
            ProjectBuilder.log("Copy", "##{file.gsub(/#{@project_path}/,'')}")
            yield "Copy: #{file.gsub(/#{@project_path}/,'')}"
          end

          
        end
      end

    end

    if is_compass_project && Compass.configuration.fireapp_build_path 
      blacklist << File.join( Compass.configuration.fireapp_build_path, "*")
    end

    blacklist.uniq!
    blacklist = blacklist.map{|x| x.sub(/^.\//, '')}
  end

  def build(build_path)
    
    release_dir = File.expand_path( build_path )
    
    FileUtils.rm_r( release_dir) if File.exists?(release_dir)
    FileUtils.mkdir_p( release_dir)

    build_html(release_dir, get_black_list(false)) do |msg|
      yield msg
    end

    build_static_file(release_dir, get_black_list(true)) do |msg|
      yield msg
    end
    
    return release_dir
  end

  def write_dynamaic_file(release_dir, request_path )
    new_file = File.join(release_dir, request_path)
    FileUtils.mkdir_p( File.dirname(  new_file ))
    puts request_path
    File.open(new_file, 'w') {|f| f.write( open("http://127.0.0.1:#{App::CONFIG['services_http_port']}#{URI.escape(request_path)}").read ) } 
  end 

end