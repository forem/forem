# frozen_string_literal: true

require 'i18n/tasks/concurrent/cached_value'

module I18n::Tasks::Concurrent
  # A thread-safe cache.
  # @since 0.9.25
  class Cache
    def initialize
      @mutex = Mutex.new
      @map = {}
    end

    # @param [Object] key
    # @return [Object] Cached or computed value.
    def fetch(key, &block)
      @mutex.synchronize do
        @map[key] ||= CachedValue.new(&block)
      end.get
    end
  end
end
