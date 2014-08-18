require "singleton"
class Tray
  include Singleton
  attr_reader :logger
  attr_reader :watching_dir
  def initialize()
    @http_server = nil
    @compass_thread = nil
    @watching_dir = nil
    @logger = nil
    @shell    = App.create_shell(Swt::SWT::ON_TOP | Swt::SWT::MODELESS)

    if org.jruby.platform.Platform::IS_MAC
      @standby_icon = App.create_image("icon/16_dark@2x.png")
      @active_icon = App.create_image("icon/16_white@2x.png")
      @watching_icon = App.create_image("icon/16@2x.png")
    else 
      @standby_icon = App.create_image("icon/16_dark.png")
      @active_icon = App.create_image("icon/16_white.png")
      @watching_icon = App.create_image("icon/16.png")
    end

    @tray_item = Swt::Widgets::TrayItem.new( App.display.system_tray, Swt::SWT::NONE)
    @tray_item.image = @standby_icon
    @tray_item.tool_tip_text = "Fire.app"
    @tray_item.addListener(Swt::SWT::Selection,  update_menu_position_handler) unless org.jruby.platform.Platform::IS_MAC
    @tray_item.addListener(Swt::SWT::MenuDetect, update_menu_position_handler)

    @menu = Swt::Widgets::Menu.new(@shell, Swt::SWT::POP_UP)
    @menu.addListener(Swt::SWT::Show, show_menu_handler)
    @menu.addListener(Swt::SWT::Hide, hide_menu_handler)

    @watch_item = add_menu_item( "Watch a Folder...", open_dir_handler)

    add_menu_separator

    @history_item = add_menu_item( "History:")

    build_history_menuitem

    add_menu_separator

    item =  add_menu_item( "Create Project", create_project_handler, Swt::SWT::CASCADE)

    item.menu = Swt::Widgets::Menu.new( @menu )
    build_compass_framework_menuitem( item.menu, create_project_handler )

    item =  add_menu_item( "Open Extensions Folder", open_extensions_folder_handler, Swt::SWT::PUSH)
    item =  add_menu_item( "Preference...", preference_handler, Swt::SWT::PUSH)

    item =  add_menu_item( "About", open_about_link_handler, Swt::SWT::CASCADE)
    item.menu = Swt::Widgets::Menu.new( @menu )
    add_menu_item( 'Homepage',                      open_about_link_handler,   Swt::SWT::PUSH, item.menu)
    add_menu_item( 'Compass ' + Compass::VERSION, open_compass_link_handler, Swt::SWT::PUSH, item.menu)
    add_menu_item( 'LiveReload.js',       open_livereloadjs_link_handler,    Swt::SWT::PUSH, item.menu)
    add_menu_item( 'Sass ' + Sass::VERSION,       open_sass_link_handler,    Swt::SWT::PUSH, item.menu)
    add_menu_item( 'Serve',       open_serve_link_handler,    Swt::SWT::PUSH, item.menu)
    add_menu_separator( item.menu )

    add_menu_item( "App Version: #{App.version}",                          nil, Swt::SWT::PUSH, item.menu)
    add_menu_item( App.compile_version, nil, Swt::SWT::PUSH, item.menu)
    add_menu_item( "Java System Properties", show_system_properties_handler, Swt::SWT::PUSH, item.menu)

    add_menu_item( "Quit",      exit_handler)
  end
  def shell 
    @shell
  end
  def run(options={})
    puts 'tray OK, spend '+(Time.now.to_f - INITAT.to_f).to_s

    if(options[:watch])
      watch(options[:watch])
    end

    SplashWindow.instance.dispose

    while(! @shell.is_disposed) do
      App.display.sleep if(!App.display.read_and_dispatch) 
      App.show_and_clean_notifications

    end

    App.display.dispose

  end

  def rewatch
    if @watching_dir
      dir = @watching_dir
      stop_watch
      watch(dir)
    end
  end

  def add_menu_separator(menu=nil, index=nil)
    menu = @menu unless menu
    if index
      Swt::Widgets::MenuItem.new(menu, Swt::SWT::SEPARATOR, index)
    else
      Swt::Widgets::MenuItem.new(menu, Swt::SWT::SEPARATOR)
    end
  end

  def add_menu_item(label, selection_handler = nil, item_type =  Swt::SWT::PUSH, menu = nil, index = nil)
    menu = @menu unless menu
    if index
      menuitem = Swt::Widgets::MenuItem.new(menu, item_type, index)
    else
      menuitem = Swt::Widgets::MenuItem.new(menu, item_type)
    end

    menuitem.text = label
    if selection_handler
      menuitem.addListener(Swt::SWT::Selection, selection_handler ) 
    else
      menuitem.enabled = false
    end
    menuitem
  end

  def add_compass_item(dir, type = :history)
    if File.exists?(dir)
      menuitem = Swt::Widgets::MenuItem.new(@menu , Swt::SWT::PUSH, @menu.indexOf(@history_item) + 1 )
      menuitem.text = "#{dir}"
      menuitem.addListener(Swt::SWT::Selection, compass_switch_handler(dir))

      
      if type == :history
        history_icon = App.create_image("icon/history-16.png")
        menuitem.setImage(history_icon)
      else
        favorite_icon = App.create_image("icon/favorite-16.png")
        menuitem.setImage(favorite_icon)
      end

      menuitem
    end
  end

  def empty_handler
    Swt::Widgets::Listener.impl do |method, evt|

    end
  end

  def clear_history
    App.clear_histoy
    rebuild_history_menuitem
  end

  def add_favorite_handler(dir)
    Swt::Widgets::Listener.impl do |method, evt|
      favorite = App.get_favorite
      history = App.get_history
      if favorite.include?(dir)
        favorite.delete(dir)
        history.unshift(dir)
      else
        favorite.unshift(dir)
        history.delete(dir)
      end
      App.set_favorite(favorite)
      @is_favorite_item.setSelection( true ) if App.get_favorite.include?(dir) && @is_favorite_item && !@is_favorite_item.isDisposed

      App.set_histoy(history)

      rebuild_history_menuitem
      
    end
  end

  def compass_switch_handler(dir)
    Swt::Widgets::Listener.impl do |method, evt|
      watch(dir, {:show_progress => true})
    end
  end

  def open_dir_handler
    Swt::Widgets::Listener.impl do |method, evt|
      if @watching_dir
        stop_watch
      else
        dia = Swt::Widgets::DirectoryDialog.new(@shell)
        dir = dia.open
        watch(dir, {:show_progress => true}) if dir 
      end
    end
  end

  def open_extensions_folder_handler
    Swt::Widgets::Listener.impl do |method, evt|
      if !File.exists?(App.shared_extensions_path)
        FileUtils.mkdir_p(App.shared_extensions_path)
        FileUtils.cp(File.join(LIB_PATH, "documents", "extensions_readme.txt"), File.join(App.shared_extensions_path, "readme.txt") )
      end

      Swt::Program.launch(App.shared_extensions_path)
    end
  end

  def open_project_handler
    Swt::Widgets::Listener.impl do |method, evt|
      Swt::Program.launch(@watching_dir)
    end
  end

  def compass_project_config
    file_name = Compass.detect_configuration_file(@watching_dir)
    Compass.add_project_configuration(file_name)
  end

  def build_change_options_panel( index )
    @changeoptions_item = add_menu_item( "Change Options...", change_options_handler , Swt::SWT::PUSH, @menu, index)
    
  end

  def build_compass_framework_menuitem( submenu, handler )
    Compass::Frameworks::ALL.each do | framework |
      next if framework.name =~ /^_/
      next if framework.template_directories.empty?

      # get default compass extension name from folder name
      if framework.templates_directory =~ /lib[\/\\]ruby[\/\\]compass_extensions[\/\\]([^\/\\]+)/
        framework_name = $1
      else
        framework_name = framework.name
      end

      item = add_menu_item( framework_name, handler, Swt::SWT::CASCADE, submenu)
      framework_submenu = Swt::Widgets::Menu.new( submenu )
      item.menu = framework_submenu
      framework.template_directories.each do | dir |
        add_menu_item( dir, handler, Swt::SWT::PUSH, framework_submenu)
      end
    end
  end

  def rebuild_history_menuitem
    delete_history_menuitem
    build_history_menuitem
  end

  def delete_history_menuitem
    @history_menuitem.each do |x|
      x.dispose if x && !x.isDisposed
    end if @history_menuitem
    @history_menuitem = []
  end

  def build_history_menuitem
    @history_menuitem ||= [] 

    App.get_history.reverse.each do | dir |
      @history_menuitem.push add_compass_item(dir, :history)
    end

    App.get_favorite.reverse.each do | dir |
      @history_menuitem.push add_compass_item(dir, :favorite)
    end

  end

  def show_system_properties_handler
    Swt::Widgets::Listener.impl do |method, evt|
      str=[]
      java.lang.System.getProperties.each do |key, value|
        str << "#{key.strip} =>  #{value.strip}"
      end
      App.report( str.join("\n\n"))
    end
  end

  def create_project_handler
    Swt::Widgets::Listener.impl do |method, evt|
      dia = Swt::Widgets::FileDialog.new(@shell,Swt::SWT::SAVE)
      dir = dia.open
      if dir
        dir.gsub!('\\','/') if org.jruby.platform.Platform::IS_WINDOWS

        # if select a pattern
        if framework = Compass::Frameworks::ALL.find{ | f| 
          f.name == evt.widget.getParent.getParentItem.text || f.templates_directory =~ %r{compass_extensions[\/\\]#{evt.widget.getParent.getParentItem.text}}
        }
          framework_name = framework.name
          pattern = evt.widget.text
        else
          framework_name = evt.widget.txt
          pattern = 'project'
        end

        App.try do 
          actual = App.get_stdout do
            Compass::Commands::CreateProject.new( dir, 
                                                 { :framework        => framework_name, 
                                                   :pattern          => pattern, 
                                                   :preferred_syntax => App::CONFIG["preferred_syntax"].to_sym 
            }).execute
          end
          App.report( actual) do
            Swt::Program.launch(dir)
          end
        end

        watch(dir)
      end
    end
  end

  def install_project_handler
    Swt::Widgets::Listener.impl do |method, evt|
      # if select a pattern
      if framework = Compass::Frameworks::ALL.find{ | f| 
        f.name == evt.widget.getParent.getParentItem.text || f.templates_directory =~ %r{compass_extensions[\/\\]#{evt.widget.getParent.getParentItem.text}}
      }
        framework_name = framework.name
        pattern = evt.widget.text
      else
        framework_name = evt.widget.txt
        pattern = 'project'
      end

      App.try do 
        actual = App.get_stdout do
          Compass::Commands::StampPattern.new( @watching_dir, 
                                              { :framework => framework_name, 
                                                :pattern => pattern,
                                                :preferred_syntax => App::CONFIG["preferred_syntax"].to_sym 
          } ).execute
        end
        App.report( actual)
      end

    end
  end

  def change_options_handler 
    Swt::Widgets::Listener.impl do |method, evt|
      ChangeOptionsPanel.instance.open
    end
  end

  def preference_handler 
    Swt::Widgets::Listener.impl do |method, evt|
      PreferencePanel.instance.open
    end
  end

  def open_about_link_handler 
    Swt::Widgets::Listener.impl do |method, evt|
      Swt::Program.launch('http://fireapp.kkbox.com')
    end
  end

  def open_compass_link_handler
    Swt::Widgets::Listener.impl do |method, evt|
      Swt::Program.launch('http://compass-style.org/')
    end
  end

  def open_sass_link_handler
    Swt::Widgets::Listener.impl do |method, evt|
      Swt::Program.launch('http://sass-lang.com/')
    end
  end

  def open_livereloadjs_link_handler
    Swt::Widgets::Listener.impl do |method, evt|
      Swt::Program.launch('https://github.com/livereload/livereload-js')
    end
  end

  def open_serve_link_handler
    Swt::Widgets::Listener.impl do |method, evt|
      Swt::Program.launch('http://get-serve.com/')
    end
  end

  def exit_handler
    Swt::Widgets::Listener.impl do |method, evt|
      stop_watch
      @shell.close
    end
  end

  def show_menu_handler
    Swt::Widgets::Listener.impl do |method, evt|
      @tray_item.image = @active_icon
    end
  end
  def hide_menu_handler
    Swt::Widgets::Listener.impl do |method, evt|
      if @watching_dir
        @tray_item.image = @watching_icon
      else
        @tray_item.image = @standby_icon
      end
    end
  end

  def update_menu_position_handler 
    Swt::Widgets::Listener.impl do |method, evt|
      @menu.visible = true
    end
  end

  def clean_project_handler
    Swt::Widgets::Listener.impl do |method, evt|
      clean_project({:show_report => true})
    end
  end

  def build_project_handler
    Swt::Widgets::Listener.impl do |method, evt|
      ENV["RACK_ENV"] = "production"

      App.try do 
        build_path = Compass.configuration.fireapp_build_path  || "build_#{Time.now.strftime('%Y%m%d%H%M%S')}"
        build_path = Pathname.new(build_path).expand_path.to_s
        
        # -- init report -- 
        if Tray.instance.compass_project_config.fireapp_always_report_on_build
          report_window = App.report('Start build project!') do
            Swt::Program.launch(build_path)
          end 
        end 

        # -- build project --
        ProjectBuilder.new(Compass.configuration.project_path).build( build_path ) do |msg|
          report_window.append msg if report_window
        end

        report_window.append "Done" if report_window

        if !Tray.instance.compass_project_config.fireapp_always_report_on_build
          if Notifier.is_support
            Notifier.notify("Build is completed", {:execute => "open #{build_path}"})
          else
            App.notify("Build is completed", App.display) 
          end
        end

      end

      
      ENV["RACK_ENV"] = "development"    
    end
  end 

  

  def deploy_project_handler
    Swt::Widgets::Listener.impl do |method, evt|
      App.try do 
        options = Compass.configuration.the_hold_options
        temp_build_folder = File.join(Dir.tmpdir, "fireapp", rand.to_s)
        #build_path = Compass.configuration.fireapp_build_path  || "build_#{Time.now.strftime('%Y%m%d%H%M%S')}"
        build_path = "build_#{Time.now.strftime('%Y%m%d%H%M%S')}"
        

        deploy_window = ProgressWindow.new
        ProjectBuilder.new(Compass.configuration.project_path).build( build_path ) do |msg| 
          deploy_window.replace(msg)
        end

        deploy_window.replace("Uploading...", false, true)
        respone = TheHoldUploader.upload_patch(build_path, options)
        if respone.code == "200"
          host=URI(options[:host]).host
          Swt::Program.launch("http://#{options[:project]}.#{options[:login]}.#{host}")
          
          App.alert("done")
        else
          App.alert(respone.body)
        end
        deploy_window.dispose

        require 'fileutils'
        FileUtils.rm_rf(build_path)

      end
    end
  end

  def clean_project(options = {}) # options = {:show_report(boolean), :show_progress(boolean)}

    options = { :show_report => false, :show_progress => false }.merge(options)

    msg_window = ProgressWindow.new if options[:show_progress]
    msg_window.replace("Building...", false, true) if msg_window

    dir = @watching_dir
    stop_watch
    App.try do 
      @logger = Compass::Logger.new({ :display => App.display, :log_dir => dir})
      actual = App.get_stdout do
        Compass::Commands::CleanProject.new(dir, {:logger => @logger}).perform
        Compass.reset_configuration!
        Compass::Commands::UpdateProject.new( dir, {:logger => @logger}).perform
        Compass.reset_configuration!
      end
      App.report( actual ) if options[:show_report]
    end
    watch(dir, {:need_stop => false})

    msg_window.dispose if msg_window
  end


  def update_config(need_clean_attr, value)
    new_config_str = "\n#{need_clean_attr} = #{value} # by Fire.app "

    file_name = Compass.detect_configuration_file(@watching_dir)

    if file_name
      new_config = ''
      last_is_blank = false
      config_file = File.new(file_name,'r').each do | x | 
        next if last_is_blank && x.strip.empty?
      new_config += x unless x =~ /by Fire\.app/ && x =~ Regexp.new(need_clean_attr)
      last_is_blank = x.strip.empty?
      end
      config_file.close
      new_config += new_config_str
      File.open(file_name, 'w'){ |f| f.write(new_config) }
    else

      config_filename = File.join(Compass.configuration.project_path, 'config.rb')

      if File.exists?(config_filename) #file "config.rb" exists!
        App.alert("can't create #{config_filename}")
        return
      end

      File.open( config_filename, 'w'){ |f| f.write(new_config_str) }
    end
  end

  def watch(dir, options = {}) # options = { :need_stop(boolean), :show_progress(boolean) }

    options = { :need_stop => true, :show_progress => false }.merge(options)

    msg_window = ProgressWindow.new if options[:show_progress]
    msg_window.replace("Watching #{dir}...", false, true) if msg_window

    dir.gsub!('\\','/') if org.jruby.platform.Platform::IS_WINDOWS
    App.try do 
      
      stop_watch if options[:need_stop] 
      @logger = Compass::Logger.new({ :display => App.display, :log_dir => dir})
      Compass.reset_configuration!
      Dir.chdir(dir)

      # update compass global configuration and make sure assert folder exists
      Compass::Commands::UpdateProject.new( dir, {:logger => @logger})

      Thread.abort_on_exception = true
      @compass_thread = Thread.new do
        Thread.current[:watcher]=AppWatcher.new(dir, {:logger=> @logger})
        Thread.current[:watcher].watch!
      end

      @tray_item.image = @watching_icon
      @watching_dir = dir

      favorite = App.get_favorite
      history = App.get_history

      @menu.items.each do |item|
        item.dispose if history.include?(item.text) || favorite.include?(item.text)
      end

      if favorite.delete(dir)
        favorite.unshift(dir)
      else 
        history.delete(dir)
        history.unshift(dir)
      end
      App.set_favorite(favorite)
      App.set_histoy(history)
      
      build_history_menuitem


      @watch_item.text="Stop watching " + dir

      @is_favorite_item = add_menu_item( "Favorite", 
                                          add_favorite_handler(dir), 
                                          Swt::SWT::CHECK,
                                          @menu, 
                                          @menu.indexOf(@watch_item) +1 )
      @is_favorite_item.setSelection( true ) if App.get_favorite.include?(dir)

      @open_project_item =  add_menu_item( "Open Project Folder", 
                                          open_project_handler, 
                                          Swt::SWT::PUSH,
                                          @menu, 
                                          @menu.indexOf(@is_favorite_item) +1 )

      @install_item =  add_menu_item( "Install...", 
                                     install_project_handler, 
                                     Swt::SWT::CASCADE,
                                     @menu, 
                                     @menu.indexOf(@open_project_item) +1 )
      @install_item.menu = Swt::Widgets::Menu.new( @menu )
      build_compass_framework_menuitem( @install_item.menu, install_project_handler )
      
      build_change_options_panel(@menu.indexOf(@install_item) +1 )

      @clean_item =  add_menu_item( "Clean && Compile", 
                                   clean_project_handler, 
                                   Swt::SWT::PUSH,
                                   @menu, 
                                   @menu.indexOf(@changeoptions_item) +1 )


      @build_project_item =  add_menu_item( "Build Project", 
                                           build_project_handler, 
                                           Swt::SWT::PUSH,
                                           @menu, 
                                           @menu.indexOf(@clean_item) +1 )
      last_item = @build_project_item
      if !Compass.configuration.the_hold_options.empty?
        @deploy_project_item =  add_menu_item( "Deploy Project", 
                                              deploy_project_handler, 
                                              Swt::SWT::PUSH,
                                              @menu, 
                                              @menu.indexOf(@build_project_item) +1 )
        last_item = @deploy_project_item
      end

      if @menu.items[ @menu.indexOf(last_item)+1 ].getStyle != Swt::SWT::SEPARATOR
        add_menu_separator(@menu, @menu.indexOf(last_item) + 1 )
      end

      if App::CONFIG['services'].include?( :http )
        require "simplehttpserver"
        @simplehttpserver_thread = Thread.new do
          SimpleHTTPServer.instance.start(Compass.configuration.project_path, :Port =>  App::CONFIG['services_http_port'])
        end
      end

      if App::CONFIG['services'].include?( :livereload )
        @simplelivereload_thread = Thread.new do
          SimpleLivereload.instance.watch(Compass.configuration.project_path, { :port => App::CONFIG["services_livereload_port"] }) 
        end
      end

      msg_window.dispose if msg_window

      return true

    end

    msg_window.dispose if msg_window

    return false
  end

  def stop_watch

    SimpleLivereload.instance.unwatch if defined?(SimpleLivereload)
    SimpleHTTPServer.instance.stop if defined?(SimpleHTTPServer)
    FSEvent.stop_all_instances if Object.const_defined?("FSEvent") && FSEvent.methods.map{|x| x.to_sym}.include?(:stop_all_instances)

    ChangeOptionsPanel.instance.close

    if @compass_thread 
      @compass_thread[:watcher].stop 
    end

    [@simplelivereload_thread, @simplehttpserver_thread, @compass_thread].each do |x|
      x.kill if x && x.alive?
    end

    @logger = nil
    @compass_thread = nil
    @simplehttpserver_thread = nil
    @simplelivereload_thread = nil

    @watch_item.text="Watch a Folder..."
    @install_item.dispose() if @install_item && !@install_item.isDisposed
    @clean_item.dispose()   if @clean_item && !@clean_item.isDisposed
    @is_favorite_item.dispose()   if @is_favorite_item && !@is_favorite_item.isDisposed
    @open_project_item.dispose()   if @open_project_item && !@open_project_item.isDisposed
    @build_project_item.dispose()  if @build_project_item && !@build_project_item.isDisposed
    @deploy_project_item.dispose() if @deploy_project_item && !@deploy_project_item.isDisposed
    @changeoptions_item.dispose()  if @changeoptions_item && !@changeoptions_item.isDisposed
    @watching_dir = nil
    @tray_item.image = @standby_icon

    rebuild_history_menuitem
  end


  def stop_livereload
    SimpleLivereload.instance.unwatch if defined?(SimpleLivereload)
    [@simplelivereload_thread].each do |x|
      x.kill if x && x.alive?
    end
    @simplelivereload_thread = nil
  end

  def start_livereload
    @simplelivereload_thread = Thread.new do
      SimpleLivereload.instance.watch(Compass.configuration.project_path, { :port => App::CONFIG["services_livereload_port"] }) 
    end
  end

  def stop_watcher
    if @compass_thread 
      @compass_thread[:watcher].stop 
    end

    [@compass_thread].each do |x|
      x.kill if x && x.alive?
    end

    @compass_thread = nil
  end


end

