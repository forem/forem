module EdgeCache
  class BustPage
    def self.call(slug)
      return unless slug

      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/page/#{slug}")
      cache_bust.call("/page/#{slug}?i=i")
      cache_bust.call("/#{slug}")
      cache_bust.call("/#{slug}?i=i")
    end
  end
end
