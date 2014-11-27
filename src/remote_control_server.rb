
require 'socket'
require "singleton"



Thread.abort_on_exception = true

class RemoteControlServer
  include Singleton

  def initialize
    @server = nil
  end

  def open(port = 13425)
    @server = Thread.new do
      TCPServer.open(13425) do |sock_server|
        
        loop {
          begin
            t = Thread.new(sock_server.accept) do |sock|
              client_port, client_ip = Socket.unpack_sockaddr_in(sock.getpeername)
              sock.puts "# Fireapp Remote Interface #"

              puts "Client Connected from #{client_ip}:#{client_port}"

              loop do
                input = sock.gets.strip
                puts "#{client_ip}:#{client_port} => #{input}"

                output = case input
                  when /^watch path \s*(.*)\s*/i
                    App.get_stdout {
                      App.display.syncExec {
                        Tray.instance.watch $1 # if exception occurred, it'll stop at here
                        puts "Watching Success: #{$1}" 
                      }
                    }


                  when /^watch lastest$/i
                    App.get_stdout {
                      App.display.syncExec {
                        if App.get_history[0]
                          Tray.instance.watch App.get_history[0] 
                          puts "Watching Success: #{App.get_history[0]}"
                        end
                      }
                    }

                  when /^extension list$/i
                    App.display.syncExec {
                      output = JSON.pretty_generate fetch_menu_tree(Tray.instance.create_item)
                    }
                    output

                  when /^create project$/i
                    App.display.syncExec {
                      click(["compass", "project"], Tray.instance.create_item)
                    }

                  when /^watch stop$/i
                    App.display.syncExec {
                      Tray.instance.stop_watch
                    }

                  when /^watch status$/i
                    "Watching: #{Tray.instance.watching_dir || "Nothing"}"




                  when /^echo (.*)/i
                    $1

                  when /^quit$/i
                    App.display.syncExec {
                      Tray.instance.exit_handler.trigger
                    }

                  when /^help$/i
                    help()
                  else 
                    "Command '#{input.strip}' is not found.\n#{help()}"
                  end

                  sock.puts output
                  puts "#{client_ip}:#{client_port} <= #{output}"
                  
              end
            end
            
          rescue Exception => e
            puts "#{e.message}"
          end
        }
      end
    end

  end

  def close
    Thread.kill(@server) if @server
    @server = nil
  end

  def open?
    not @server.nil?
  end

  def help
    [
      "** We support following commands:",
      "- watch path [path]",
      "- watch stop",
      "- watch status",
      "- watch lastest",
      "- extension list",
      "- quit",
      "- echo [msg]",
      "- help",
      ""
    ].join("\n")
  end


  def fetch_menu_tree (menuitem)
    
    if menuitem.menu
      tree = Hash.new
      menuitem.menu.getItems.each do |item|
        tree[item.text] = fetch_menu_tree(item)
      end
      tree
    else
      ""
    end

  end

  def click (steps = [], menuitem = nil)
    menuitem = menuitem || Tray.instance.tray_item
    step = steps[0]
    if step and menuitem.menu
      next_menuitem = menuitem.menu.getItems.find {|f| f.text.strip =~ Regexp.new(step) }
      if next_menuitem and steps.size == 1
        menuitem.getListeners(Swt::SWT::Selection).each { |l| l.trigger }
      elsif next_menuitem
        return click(steps[1..-1], next_menuitem)
      end
    else
      return false
    end

  end

end



#server_thread.join