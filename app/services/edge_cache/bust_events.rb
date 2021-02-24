module EdgeCache
  class BustEvents < Buster
    def self.call
      buster = EdgeCache::Buster.new
      buster.bust("/events")
      buster.bust("/events?i=i")
    end
  end
end
