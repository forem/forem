module EdgeCache
  class BustEvents
    def self.call
      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/events")
      cache_bust.call("/events?i=i")
    end
  end
end
