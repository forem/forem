module EdgeCache
  class BustTag
    def self.call(tag)
      return unless tag

      tag.purge

      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/t/#{tag.name}")
      cache_bust.call("/t/#{tag.name}?i=i")
      cache_bust.call("/t/#{tag.name}/?i=i")
      cache_bust.call("/t/#{tag.name}/")
      cache_bust.call("/tags")
    end
  end
end
