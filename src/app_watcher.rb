module Compass
  module Watcher
    class  AppWatcher < ProjectWatcher
      def initialize(project_path, watches=[], options={}, poll=false)
        super
        @sass_watchers +=[]
        setup_listener
      end

      def watch!
        compile
        super
      end
    end
  end
end
