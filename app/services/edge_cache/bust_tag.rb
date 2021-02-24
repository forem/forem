module EdgeCache
  class BustTag < Buster
    def self.call(tag)
      return unless tag

      tag.purge

      buster = EdgeCache::Buster.new
      buster.bust("/t/#{tag.name}")
      buster.bust("/t/#{tag.name}?i=i")
      buster.bust("/t/#{tag.name}/?i=i")
      buster.bust("/t/#{tag.name}/")
      buster.bust("/tags")
    end
  end
end
