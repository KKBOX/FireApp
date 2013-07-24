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

    @isChanged = false
  end

  def close
    @shell.dispose if @shell and !@shell.isDisposed
  end

  def close
    @shell.dispose if @shell and !@shell.isDisposed
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
    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    panel_title_label.setLayoutData( layoutdata )

    # -- horizontal separator --
    horizontal_separator = Swt::Widgets::Label.new(@shell, Swt::SWT::SEPARATOR | Swt::SWT::HORIZONTAL)
    layoutdata = Swt::Layout::FormData.new(390, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( panel_title_label, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( panel_title_label, 10, Swt::SWT::BOTTOM)
    horizontal_separator.setLayoutData( layoutdata )


    # -- context group --
    @general_group = build_general_group(horizontal_separator)
    @sass_group = build_sass_group(@general_group)
    @coffeescript_group = build_coffeescript_group(@sass_group)
    @livescript_group = build_livescript_group(@coffeescript_group)
    @buildoption_group = build_buildoption_group(@livescript_group)
    # @thehold_group = build_thehold_group(@coffeescript_group)

    # -- control button --
    # build_control_button(@thehold_group)
    build_control_button(@buildoption_group)
    
    
    @shell.pack
  end


  def build_dir_label_on_general_group(group, text, align)
    dir_label = Swt::Widgets::Label.new(group, Swt::SWT::PUSH)
    layoutdata = Swt::Layout::FormData.new(120, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( align, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( align, 10, Swt::SWT::BOTTOM)
    dir_label.setLayoutData( layoutdata )
    dir_label.setText(text)
    dir_label.pack
    dir_label
  end

  def build_dir_text_on_general_group(group, text, align)
    layoutdata = Swt::Layout::FormData.new(180, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( align, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( align, 0, Swt::SWT::CENTER)
    dir_text  = Swt::Widgets::Text.new(group, Swt::SWT::BORDER)
    dir_text.setLayoutData( layoutdata )
    dir_text.setText( text ) if text
    dir_text.addListener(Swt::SWT::Selection, change_handler)
    dir_text
  end

  def build_select_button_on_general_group(group, swttext, align = nil)
    # -- dir button --
    align = swttext if align
    select_dir_btn = Swt::Widgets::Button.new(group, Swt::SWT::PUSH | Swt::SWT::CENTER)
    select_dir_btn.setText('Select')
    button_width = 70
    button_width = button_width - 10 if org.jruby.platform.Platform::IS_WINDOWS
    layoutdata = Swt::Layout::FormData.new(button_width, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( swttext, 1, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( swttext, 0, Swt::SWT::CENTER)
    select_dir_btn.setLayoutData( layoutdata )
    select_dir_btn.addListener(Swt::SWT::Selection, select_handler(swttext))
  end

  def build_general_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText('General')

    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- sass dir --
    sass_dir_label = build_dir_label_on_general_group(group, "Sass Dir:", group)
    @sass_dir_text = build_dir_text_on_general_group(group, Tray.instance.compass_project_config.sass_dir, sass_dir_label)
    build_select_button_on_general_group(group, @sass_dir_text)

    # -- coffeescripts dir --
    coffeescripts_dir_label = build_dir_label_on_general_group(group, "CoffeeScripts Dir:", sass_dir_label)
    @coffeescripts_dir_text = build_dir_text_on_general_group(group, Tray.instance.compass_project_config.fireapp_coffeescripts_dir, coffeescripts_dir_label)
    build_select_button_on_general_group(group, @coffeescripts_dir_text)

    # -- livescripts dir --
    livescripts_dir_label = build_dir_label_on_general_group(group, "LiveScripts Dir:", coffeescripts_dir_label)
    @livescripts_dir_text = build_dir_text_on_general_group(group, Tray.instance.compass_project_config.fireapp_livescripts_dir, livescripts_dir_label)
    build_select_button_on_general_group(group, @livescripts_dir_text)

    # -- css dir --
    css_dir_label = build_dir_label_on_general_group(group, "Css Dir:", livescripts_dir_label)
    @css_dir_text = build_dir_text_on_general_group(group, Tray.instance.compass_project_config.css_dir, css_dir_label)
    build_select_button_on_general_group(group, @css_dir_text)

    # -- images dir --
    images_dir_label = build_dir_label_on_general_group(group, "Images Dir:", css_dir_label)
    @images_dir_text = build_dir_text_on_general_group(group, Tray.instance.compass_project_config.images_dir, images_dir_label)
    build_select_button_on_general_group(group, @images_dir_text)

    # -- javascripts dir --
    js_dir_label = build_dir_label_on_general_group(group, "Javascripts Dir:", images_dir_label)
    @js_dir_text = build_dir_text_on_general_group(group, Tray.instance.compass_project_config.javascripts_dir, js_dir_label)
    build_select_button_on_general_group(group, @js_dir_text)


    group.pack

    group
  end

  def build_sass_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText("Sass")

    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
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

    # -- disable on build checkbox --
    layoutdata = Swt::Layout::FormData.new(350, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( @debug_info_button, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( @debug_info_button, 10, Swt::SWT::BOTTOM)
    @disable_linecomments_and_debuginfo_on_build_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @disable_linecomments_and_debuginfo_on_build_button.setText( 'Disable Line Comments ＆ Debug Info on Build' )
    @disable_linecomments_and_debuginfo_on_build_button.setLayoutData( layoutdata )
    @disable_linecomments_and_debuginfo_on_build_button.setSelection(true) if Tray.instance.compass_project_config.fireapp_disable_linecomments_and_debuginfo_on_build 



    group.pack

    group
  end

def build_buildoption_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText("Build")

    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- minifyjs_on_build checkbox --
    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    @minifyjs_on_build_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @minifyjs_on_build_button.setText( 'Minifyjs on Build' )
    @minifyjs_on_build_button.setLayoutData( layoutdata )
    @minifyjs_on_build_button.setSelection( true ) if Tray.instance.compass_project_config.fireapp_minifyjs_on_build

    # -- always_report_on_build checkbox --
    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( @minifyjs_on_build_button, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( @minifyjs_on_build_button, 10, Swt::SWT::BOTTOM)
    @always_report_on_build_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @always_report_on_build_button.setText( 'Always Report on Build' )
    @always_report_on_build_button.setLayoutData( layoutdata )
    @always_report_on_build_button.setSelection( true ) if Tray.instance.compass_project_config.fireapp_always_report_on_build



    group.pack

    group
  end

  def build_coffeescript_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText("CoffeeScript")

    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- bare checkbox --
    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    @coffeescripts_bare_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @coffeescripts_bare_button.setText( 'Bare' )
    @coffeescripts_bare_button.setLayoutData( layoutdata )

    #puts 'fireapp_coffeescript_options: '+Tray.instance.compass_project_config.fireapp_coffeescript_options.to_s
    #puts Tray.instance.compass_project_config.fireapp_coffeescript_options.is_a?(Hash)
    @coffeescripts_bare_button.setSelection( true ) if Tray.instance.compass_project_config.fireapp_coffeescript_options[:bare]

    group.pack

    group
  end

  def build_livescript_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText("LiveScript")

    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    layoutdata.left = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::LEFT )
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    group.setLayoutData( layoutdata )

    layout = Swt::Layout::FormLayout.new
    layout.marginWidth = layout.marginHeight = 5
    group.setLayout( layout )

    # -- bare checkbox --
    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
    @livescripts_bare_button = Swt::Widgets::Button.new(group, Swt::SWT::CHECK )
    @livescripts_bare_button.setText( 'Bare' )
    @livescripts_bare_button.setLayoutData( layoutdata )

    @livescripts_bare_button.setSelection( true ) if Tray.instance.compass_project_config.fireapp_livescript_options[:bare]

    group.pack

    group
  end

  def build_thehold_group(behind)
    group = Swt::Widgets::Group.new(@shell, Swt::SWT::SHADOW_ETCHED_OUT)
    group.setText('TheHold')

    layoutdata = Swt::Layout::FormData.new(380, Swt::SWT::DEFAULT)
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

    button_width = 90
    button_width = button_width - 10 if org.jruby.platform.Platform::IS_WINDOWS

    # -- save button --
    save_btn = Swt::Widgets::Button.new(@shell, Swt::SWT::PUSH | Swt::SWT::CENTER)
    save_btn.setText('Save')
    layoutdata = Swt::Layout::FormData.new(button_width, Swt::SWT::DEFAULT)
    layoutdata.right = Swt::Layout::FormAttachment.new( behind, 0, Swt::SWT::RIGHT)
    layoutdata.top  = Swt::Layout::FormAttachment.new( behind, 10, Swt::SWT::BOTTOM)
    save_btn.setLayoutData( layoutdata )
    save_btn.addListener(Swt::SWT::Selection, save_handler)
    save_btn.pack

    # -- cancel button --
    cancel_btn = Swt::Widgets::Button.new(@shell, Swt::SWT::PUSH | Swt::SWT::CENTER)
    cancel_btn.setText('Cancel')
    layoutdata = Swt::Layout::FormData.new(button_width, Swt::SWT::DEFAULT)
    layoutdata.right = Swt::Layout::FormAttachment.new( save_btn, 5, Swt::SWT::LEFT)
    layoutdata.right = Swt::Layout::FormAttachment.new( save_btn, -5, Swt::SWT::LEFT) if org.jruby.platform.Platform::IS_WINDOWS
    layoutdata.top  = Swt::Layout::FormAttachment.new( save_btn, 0, Swt::SWT::CENTER)
    cancel_btn.setLayoutData( layoutdata )
    cancel_btn.addListener(Swt::SWT::Selection, cancel_handler)
    cancel_btn.pack
  end


  def change_handler
    Swt::Widgets::Listener.impl do |method, evt|   
      @isChanged = true
    end
  end

  def cancel_handler
    Swt::Widgets::Listener.impl do |method, evt|   
      close
    end
  end

  def select_handler(swttext)
    Swt::Widgets::Listener.impl do |method, evt|   
      dia = Swt::Widgets::DirectoryDialog.new(@shell)
      dia.setFilterPath(Tray.instance.watching_dir)
      dir = dia.open
      dir_path = Pathname.new(dir) if !dir.nil? 
      watching_dir_path = Pathname.new(Tray.instance.watching_dir)

      if dir.nil? || dir_path.realpath == watching_dir_path.realpath then
        nil
      elsif !dir_path.relative_path_from(watching_dir_path).to_s.split('/').include?('..') 
        swttext.setText(dir_path.relative_path_from(watching_dir_path).to_s) 
        swttext.forceFocus
      else
        App.alert("Can't use this folder.")
      end
    end
  end

  def save_handler
    Swt::Widgets::Listener.impl do |method, evt|
      evt.widget.shell.setVisible( false )

      #App.alert("Already stop watch project") Tray.instance.watching_dir
      #evt.widget.shell.dispose if Tray.instance.watching_dir

      msg_window = ProgressWindow.new
      msg_window.replace('Regenerating...', false, true)

      # -- update general --
      # Tray.instance.update_config( "http_path", @http_path_text.getText.inspect )
      Tray.instance.update_config( "css_dir", @css_dir_text.getText.inspect )
      Tray.instance.update_config( "sass_dir", @sass_dir_text.getText.inspect )
      Tray.instance.update_config( "images_dir", @images_dir_text.getText.inspect )
      Tray.instance.update_config( "javascripts_dir", @js_dir_text.getText.inspect )
      Tray.instance.update_config( "fireapp_coffeescripts_dir", @coffeescripts_dir_text.getText.inspect )
      Tray.instance.update_config( "fireapp_livescripts_dir", @livescripts_dir_text.getText.inspect )
      Tray.instance.update_config( "fireapp_minifyjs_on_build", @minifyjs_on_build_button.getSelection )
      Tray.instance.update_config( "fireapp_always_report_on_build", @always_report_on_build_button.getSelection )

      # -- update output style --
      Tray.instance.update_config( "output_style", ":"+@output_style_combo.getItem(@output_style_combo.getSelectionIndex).to_s )

      # -- update line comments --
      Tray.instance.update_config( "line_comments", @line_comments_button.getSelection )

      # -- update sass options --
      sass_options = Tray.instance.compass_project_config.sass_options
      sass_options = {} if !sass_options.is_a? Hash
      sass_options[:debug_info] = @debug_info_button.getSelection
      Tray.instance.update_config( "sass_options", sass_options.inspect )

      # -- disable line comments & debug info--
      Tray.instance.update_config( "fireapp_disable_linecomments_and_debuginfo_on_build", @disable_linecomments_and_debuginfo_on_build_button.getSelection )
      

      # -- update coffeescript bare -- 
      fireapp_coffeescript_options = Tray.instance.compass_project_config.fireapp_coffeescript_options
      fireapp_coffeescript_options.update({:bare => @coffeescripts_bare_button.getSelection })
      Tray.instance.update_config( "fireapp_coffeescript_options", fireapp_coffeescript_options.inspect)

      # -- update livescript bare -- 
      fireapp_livescript_options = Tray.instance.compass_project_config.fireapp_livescript_options
      fireapp_livescript_options.update({:bare => @livescripts_bare_button.getSelection })
      Tray.instance.update_config( "fireapp_livescript_options", fireapp_livescript_options.inspect)


      # -- update the_hold bare -- 
      #the_hold_options = Tray.instance.compass_project_config.the_hold_options
      #the_hold_options.update({
      #  :login => @user_name_text.getText,
      #  :token => @api_key_text.getText,
      #  :project => @project_name_text.getText,
      #  :project_site_password => @project_password_text.getText
      #})
      #Tray.instance.update_config( "the_hold_options", the_hold_options.inspect)

      # Compass::Commands::CleanProject.new(Tray.instance.watching_dir, {}).perform
      Tray.instance.clean_project

      msg_window.dispose
      close
    end
  end

  

end
