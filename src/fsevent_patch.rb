class FSEvent
  def self.stop_all_instances
    system('killall fsevent_watch_for_fire_app')
  end
end
