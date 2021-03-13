module EdgeCache
  class BustSidebar
    def self.call
      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/sidebars/home")
    end
  end
end
