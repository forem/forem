module EdgeCache
  class BustPage < Buster
    def self.call(slug)
      return unless slug

      buster = EdgeCache::Buster.new
      buster.bust("/page/#{slug}")
      buster.bust("/page/#{slug}?i=i")
      buster.bust("/#{slug}")
      buster.bust("/#{slug}?i=i")
    end
  end
end
