class FSEvent
  def self.stop_all_instances
    system('killall fsevent_watch_for_fire_app')
    system('killall fsevent_watch_for_fire_app_lion')
  end
  def stop
    if pipe
      Process.kill("KILL", pipe.pid)
      pipe.close
    end 
  rescue 
  ensure
    @pipe = false
  end
end
