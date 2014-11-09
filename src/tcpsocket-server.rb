
require 'socket'



Thread.abort_on_exception = true
server_thread = Thread.new do
  TCPServer.open(13425) do |sock_server|
    
    loop {
      begin
        t = Thread.new(sock_server.accept) do |sock|
          client_port, client_ip = Socket.unpack_sockaddr_in(sock.getpeername)
          sock.puts "# Fireapp Remote Interface #"

          puts "Client Connected from #{client_ip}:#{client_port}"

          loop do
            input = sock.gets
            puts "#{client_ip}:#{client_port} => #{input}"

            case input
              when /^watch path \s*(.*)\s*/i
                output = App.get_stdout {
                  App.display.syncExec {
                    Tray.instance.watch $1
                  }
                }
                sock.puts output
                puts "#{client_ip}:#{client_port} <= #{output}"

              when /^watch stop$/i
                output App.display.syncExec {
                  Tray.instance.stop_watch
                }

                sock.puts output
                puts "#{client_ip}:#{client_port} <= #{output}"
                
              when /^echo (.*)/i
                output = $1
                sock.puts output
                puts "#{client_ip}:#{client_port} <= #{output}"
              end
              
          end
        end
        
      rescue Exception => e
        puts "#{e.message}"
      end
    }
  end
end

#server_thread.join