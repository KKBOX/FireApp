
require 'socket'

def help
  [
    "** We support following commands:",
    "- watch path [path]",
    "- watch stop",
    "- watch status",
    "- quit",
    "- echo [msg]",
    "- help",
    ""
  ].join("\n")
end


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
            input = sock.gets.strip
            puts "#{client_ip}:#{client_port} => #{input}"

            output = case input
              when /^watch path \s*(.*)\s*/i
                App.get_stdout {
                  App.display.syncExec {
                    Tray.instance.watch $1
                  }
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

#server_thread.join