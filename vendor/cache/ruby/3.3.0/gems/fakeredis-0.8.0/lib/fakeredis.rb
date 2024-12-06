require 'redis'
require 'redis/connection/memory'

module FakeRedis
  Redis = ::Redis

  def self.enable
    Redis::Connection.drivers << Redis::Connection::Memory unless enabled?
  end

  def self.enabled?
    Redis::Connection.drivers.last == Redis::Connection::Memory
  end

  def self.disable
    Redis::Connection.drivers.delete_if {|driver| Redis::Connection::Memory == driver }
  end

  def self.disabling
    return yield unless enabled?

    disable
    yield
    enable
  end

  def self.enabling
    return yield if enabled?

    enable
    yield
    disable
  end
end
