
require "base_compass_hooker"
require "singleton"

module CompassHooker

  class WatchHooker < BaseCompassHooker
    include Singleton

    def watch(glob, &block)
      Compass.configuration.watch(glob, &block)
    end

    def watches
      Compass.configuration.watches
    end

  end

end