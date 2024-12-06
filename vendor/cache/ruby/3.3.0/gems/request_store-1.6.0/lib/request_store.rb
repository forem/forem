require "request_store/version"
require "request_store/middleware"
require "request_store/railtie" if defined?(Rails::Railtie)

module RequestStore
  if Fiber.respond_to?(:[])
    def self.scope
      Fiber
    end
  else
    def self.scope
      Thread.current
    end
  end

  def self.store
    scope[:request_store] ||= {}
  end

  def self.store=(store)
    scope[:request_store] = store
  end

  def self.clear!
    scope[:request_store] = {}
  end

  def self.begin!
    scope[:request_store_active] = true
  end

  def self.end!
    scope[:request_store_active] = false
  end

  def self.active?
    scope[:request_store_active] || false
  end

  def self.read(key)
    store[key]
  end

  def self.[](key)
    store[key]
  end

  def self.write(key, value)
    store[key] = value
  end

  def self.[]=(key, value)
    store[key] = value
  end

  def self.exist?(key)
    store.key?(key)
  end

  def self.fetch(key)
    store[key] = yield unless exist?(key)
    store[key]
  end

  def self.delete(key, &block)
    store.delete(key, &block)
  end
end
