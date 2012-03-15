require "singleton"
class SplashWindow
  include Singleton
  def initialize(msg="Starting", target_display = nil, &block)
    target_display = Swt::Widgets::Display.get_current unless target_display
      @shell = Swt::Widgets::Shell.new(target_display, Swt::SWT::BORDER|Swt::SWT::ON_TOP)
      @shell.setText("Fire.app")
      @shell.setBackgroundMode(Swt::SWT::INHERIT_DEFAULT)
      @shell.setSize(400,80)
      layout = Swt::Layout::GridLayout.new
      layout.numColumns = 2;
      @shell.layout = layout

      gridData = Swt::Layout::GridData.new
      gridData.horizontalAlignment = Swt::SWT::LEFT;
      gridData.verticalAlignment = Swt::SWT::CENTER;
      @img_label = Swt::Widgets::Label.new(@shell, Swt::SWT::LEFT)
      img= Swt::Graphics::Image.new( Swt::Widgets::Display.get_current, java.io.FileInputStream.new( File.join(LIB_PATH, 'images', 'icon', '64.png')))

      @img_label.setImage( img )
      @img_label.setLayoutData(gridData)

      gridData = Swt::Layout::GridData.new
      gridData.horizontalAlignment = Swt::Layout::GridData::FILL;
      gridData.verticalAlignment = Swt::SWT::CENTER;
      gridData.grabExcessHorizontalSpace = true;
      gridData.grabExcessVerticalSpace = true;
      @label = Swt::Widgets::Label.new(@shell, Swt::SWT::LEFT)
      @label.setText(msg)
      @label.setLayoutData(gridData)


      @monior=target_display.getPrimaryMonitor().getBounds();
      rect = @shell.getClientArea();
      @shell.setLocation((@monior.width-rect.width) /2, (@monior.height-rect.height) /2) 
      @shell.open
      @shell.forceActive
      @img_label.redraw
  end

  def replace(msg)
    @label.text = msg
    @label.update
    @label.pack
  end

  def dispose
    @shell.dispose
  end

  def shell
    @shell
  end
end
