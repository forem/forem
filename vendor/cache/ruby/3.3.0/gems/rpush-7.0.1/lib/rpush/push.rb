module Rpush
  def self.push
    require 'rpush/daemon'

    Rpush.config.push = true
    Rpush::Daemon.common_init
    Rpush::Daemon::Synchronizer.sync
    Rpush::Daemon::Feeder.start(true) # non-blocking
    Rpush::Daemon::AppRunner.stop
  end
end
