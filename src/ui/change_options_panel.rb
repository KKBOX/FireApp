require 'singleton'

class ChangeOptionsPanel
  include Singleton


  def initialize()
    @display = Swt::Widgets::Display.get_current
  end

  def open
    self.create_window if !@shell || @shell.isDisposed
    m=@display.getPrimaryMonitor().getBounds()
    rect = @shell.getClientArea()
    @shell.setLocation((m.width-rect.width) /2, (m.height-rect.height) /2) 
    @shell.open
    @shell.forceActive
  end

  def create_window
    @shell = Swt::Widgets::Shell.new(@display, Swt::SWT::DIALOG_TRIM)
    @shell.setText("Change Options")
    @shell.setBackgroundMode(Swt::SWT::INHERIT_DEFAULT)
   
    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 15
    @shell.layout = layout

    # -- panel title label --
    panel_title_label = Swt::Widgets::Label.new(@shell, Swt::SWT::LEFT)
    font_data=panel_title_label.getFont().getFontData()
    font_data.each do |fd|
      fd.setStyle(Swt::SWT::BOLD)
      fd.setHeight(14)
    end
    font=Swt::Graphics::Font.new(@display, font_data)
    panel_title_label.setFont(font)
    panel_title_label.setText("Project Options")
    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    panel_title_label.setLayoutData( layoutdata )

    # -- horizontal separator --
    horizontal_separator = Swt::Widgets::Label.new(@shell, Swt::SWT::SEPARATOR | Swt::SWT::HORIZONTAL)
    layoutdata = Swt::Layout::FormData.new(360, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( panel_title_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( panel_title_label, 10, Swt::SWT::BOTTOM)
    horizontal_separator.setLayoutData( layoutdata )


    # -- context group --
    @general_group = build_general(horizontal_separator)
    @sass_group = build_sass_group(@general_group)
    @coffeescript_group = build_coffeescript_group(@sass_group)
    # @thehold_group = build_thehold_group(@coffeescript_group)

    # -- control button --
    # build_control_button(@thehold_group)
    build_control_button(@coffeescript_group)
    
    
    @shell.pack
  end

  def build_general(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText('General')

    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- http path label --
    http_path_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    http_path_label.setLayoutData( layoutdata )
    http_path_label.setText("Http Path:")
    http_path_label.pack

    # -- http path text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( http_path_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( http_path_label, 0, Swt::SWT::CENTER)
    @http_path_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @http_path_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.http_path
    @http_path_text.setText( text ) if text

    # -- css dir label --
    css_dir_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( http_path_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( http_path_label, 10, Swt::SWT::BOTTOM)
    css_dir_label.setLayoutData( layoutdata )
    css_dir_label.setText("Css Dir:")
    css_dir_label.pack

    # -- css dir text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( css_dir_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( css_dir_label, 0, Swt::SWT::CENTER)
    @css_dir_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @css_dir_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.css_dir
    @css_dir_text.setText( text ) if text


    # -- sass dir label --
    sass_dir_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( css_dir_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( css_dir_label, 10, Swt::SWT::BOTTOM)
    sass_dir_label.setLayoutData( layoutdata )
    sass_dir_label.setText("Sass Dir:")
    sass_dir_label.pack

    # -- sass dir text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( sass_dir_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( sass_dir_label, 0, Swt::SWT::CENTER)
    @sass_dir_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @sass_dir_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.sass_dir
    @sass_dir_text.setText( text ) if text

    # -- images dir label --
    images_dir_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( sass_dir_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( sass_dir_label, 10, Swt::SWT::BOTTOM)
    images_dir_label.setLayoutData( layoutdata )
    images_dir_label.setText("Images Dir:")
    images_dir_label.pack

    # -- images dir text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( images_dir_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( images_dir_label, 0, Swt::SWT::CENTER)
    @images_dir_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @images_dir_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.images_dir
    @images_dir_text.setText( text ) if text

    # -- javascripts dir label --
    js_dir_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( images_dir_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( images_dir_label, 10, Swt::SWT::BOTTOM)
    js_dir_label.setLayoutData( layoutdata )
    js_dir_label.setText("JS Dir:")
    js_dir_label.pack

    # -- javascripts dir text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( js_dir_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( js_dir_label, 0, Swt::SWT::CENTER)
    @js_dir_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @js_dir_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.javascripts_dir
    @js_dir_text.setText( text ) if text

    # -- javascripts dir label --
    coffeescripts_dir_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( js_dir_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( js_dir_label, 10, Swt::SWT::BOTTOM)
    coffeescripts_dir_label.setLayoutData( layoutdata )
    coffeescripts_dir_label.setText("CoffeeScripts Dir:")
    coffeescripts_dir_label.pack

    # -- javascripts dir text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( coffeescripts_dir_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( coffeescripts_dir_label, 0, Swt::SWT::CENTER)
    @coffeescripts_dir_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @coffeescripts_dir_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.fireapp_coffeescripts_dir
    @coffeescripts_dir_text.setText( text ) if text

    # -- minifyjs_on_build checkbox --
    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( coffeescripts_dir_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( coffeescripts_dir_label, 10, Swt::SWT::BOTTOM)
    @minifyjs_on_build_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @minifyjs_on_build_button.setText( 'Minifyjs on Build' )
    @minifyjs_on_build_button.setLayoutData( layoutdata )
    @minifyjs_on_build_button.setSelection( true ) if Tray.instance.compass_project_config.fireapp_minifyjs_on_build


    group.pack

    group
  end

  def build_sass_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText("Sass")

    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- output style label -- 
    output_style_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    output_style_label.setText("Output Style:")
    output_style_label.pack

    # -- output style combo --
    layoutdata = Swt::Layout::FormData.new(100, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( output_style_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( output_style_label, 0, Swt::SWT::CENTER)
    @output_style_combo  = Swt::Widgets::Combo.new(group, Swt::SWT::DEFAULT)
    @output_style_combo.setLayoutData( layoutdata )
    %W{nested expanded compact compressed}.each do |output_style|
      @output_style_combo.add(output_style)
    end
    @output_style_combo.setText( Tray.instance.compass_project_config.output_style.to_s )

    # -- line comments checkbox --
    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( output_style_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( output_style_label, 10, Swt::SWT::BOTTOM)
    @line_comments_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @line_comments_button.setText( 'Line Comments' )
    @line_comments_button.setLayoutData( layoutdata )
    @line_comments_button.setSelection(true) if Tray.instance.compass_project_config.line_comments

    # -- debug info checkbox --
    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( @line_comments_button, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( @line_comments_button, 10, Swt::SWT::BOTTOM)
    @debug_info_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @debug_info_button.setText( 'Debug Info' )
    @debug_info_button.setLayoutData( layoutdata )
    @debug_info_button.setSelection(true) if Tray.instance.compass_project_config.sass_options && Tray.instance.compass_project_config.sass_options[:debug_info] 

    group.pack

    group
  end

  def build_coffeescript_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText("CoffeeScript")

    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- bare checkbox --
    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    @bare_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @bare_button.setText( 'Bare' )
    @bare_button.setLayoutData( layoutdata )

    #puts 'fireapp_coffeescript_options: '+Tray.instance.compass_project_config.fireapp_coffeescript_options.to_s
    #puts Tray.instance.compass_project_config.fireapp_coffeescript_options.is_a?(Hash)
    @bare_button.setSelection( true ) if Tray.instance.compass_project_config.fireapp_coffeescript_options[:bare]

    group.pack

    group
  end

  def build_thehold_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText('TheHold')

    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- api key label --
    api_key_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    api_key_label.setLayoutData( layoutdata )
    api_key_label.setText("Api Key:")
    api_key_label.pack

    # -- api key text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( api_key_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( api_key_label, 0, Swt::SWT::CENTER)
    @api_key_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @api_key_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.the_hold_options[:token]
    @api_key_text.setText( text ) if text

    # -- user name label --
    user_name_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( api_key_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( api_key_label, 10, Swt::SWT::BOTTOM)
    user_name_label.setLayoutData( layoutdata )
    user_name_label.setText("User Name:")
    user_name_label.pack

    # -- user name text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( user_name_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( user_name_label, 0, Swt::SWT::CENTER)
    @user_name_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @user_name_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.the_hold_options[:login]
    @user_name_text.setText( text ) if text


    # -- project name label --
    project_name_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( user_name_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( user_name_label, 10, Swt::SWT::BOTTOM)
    project_name_label.setLayoutData( layoutdata )
    project_name_label.setText("Project Name:")
    project_name_label.pack

    # -- project name text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( project_name_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( project_name_label, 0, Swt::SWT::CENTER)
    @project_name_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @project_name_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.the_hold_options[:project]
    @project_name_text.setText( text ) if text

    # -- project password label --
    project_password_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( project_name_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( project_name_label, 10, Swt::SWT::BOTTOM)
    project_password_label.setLayoutData( layoutdata )
    project_password_label.setText("Project Password:")
    project_password_label.pack

    # -- project password text --
    layoutdata = Swt::Layout::FormData.new(200, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( project_password_label, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( project_password_label, 0, Swt::SWT::CENTER)
    @project_password_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    @project_password_text.setLayoutData( layoutdata )
    text = Tray.instance.compass_project_config.the_hold_options[:project_site_password]
    @project_password_text.setText( text ) if text

    group.pack

    group
  end

  def build_control_button(behind)
    # -- save button --
    save_btn = Swt::Widgets::Button.new(@shell, Swt::SWT::PUSH | Swt::SWT::CENTER)
    save_btn.setText('Save')
    layoutdata = Swt::Layout::FormData.new(100, Swt::SWT::DEFAULT)
    layoutdata.right = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    save_btn.setLayoutData( layoutdata )
    save_btn.addListener(Swt::SWT::Selection, save_handler)

    # -- cancel button --
    cancel_btn = Swt::Widgets::Button.new(@shell, Swt::SWT::PUSH | Swt::SWT::CENTER)
    cancel_btn.setText('Cancel')
    layoutdata = Swt::Layout::FormData.new(90, Swt::SWT::DEFAULT)
    layoutdata.right = Swt::Layout::FormAttachment.new( save_btn, 5, Swt::SWT::LEFT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( save_btn, 0, Swt::SWT::CENTER)
    cancel_btn.setLayoutData( layoutdata )
    cancel_btn.addListener(Swt::SWT::Selection, cancel_handler)
  end

  def cancel_handler
    Swt::Widgets::Listener.impl do |method, evt|   
      evt.widget.shell.dispose();
    end
  end

  def save_handler
    Swt::Widgets::Listener.impl do |method, evt|
      evt.widget.shell.setVisible( false )
      msg_window = ProgressWindow.new
      msg_window.replace('Saving...', false, true)

      # -- update general --
      Tray.instance.update_config( "http_path", @http_path_text.getText.inspect )
      Tray.instance.update_config( "css_dir", @css_dir_text.getText.inspect )
      Tray.instance.update_config( "sass_dir", @sass_dir_text.getText.inspect )
      Tray.instance.update_config( "images_dir", @images_dir_text.getText.inspect )
      Tray.instance.update_config( "javascripts_dir", @js_dir_text.getText.inspect )
      Tray.instance.update_config( "fireapp_coffeescripts_dir", @coffeescripts_dir_text.getText.inspect )
      Tray.instance.update_config( "fireapp_minifyjs_on_build", @minifyjs_on_build_button.getSelection )

      # -- update output style --
      Tray.instance.update_config( "output_style", ":"+@output_style_combo.getItem(@output_style_combo.getSelectionIndex).to_s )

      # -- update line comments --
      Tray.instance.update_config( "line_comments", @line_comments_button.getSelection )

      # -- update sass options --
      sass_options = Tray.instance.compass_project_config.sass_options
      sass_options = {} if !sass_options.is_a? Hash
      sass_options[:debug_info] = @debug_info_button.getSelection
      Tray.instance.update_config( "sass_options", sass_options.inspect )

      # -- update coffeescript bare -- 
      fireapp_coffeescript_options = Tray.instance.compass_project_config.fireapp_coffeescript_options
      fireapp_coffeescript_options.update({:bare => @bare_button.getSelection })
      Tray.instance.update_config( "fireapp_coffeescript_options", fireapp_coffeescript_options.inspect)


      # -- update the_hold bare -- 
      #the_hold_options = Tray.instance.compass_project_config.the_hold_options
      #the_hold_options.update({
      #  :login => @user_name_text.getText,
      #  :token => @api_key_text.getText,
      #  :project => @project_name_text.getText,
      #  :project_site_password => @project_password_text.getText
      #})
      #Tray.instance.update_config( "the_hold_options", the_hold_options.inspect)

      Compass::Commands::CleanProject.new(Tray.instance.watching_dir, {}).perform
      Tray.instance.clean_project

      msg_window.dispose
      evt.widget.shell.dispose();
    end
  end

  

end
