module EdgeCache
  class BustPodcast < Buster
    def self.call(path)
      return unless path

      buster = EdgeCache::Buster.new
      buster.bust("/#{path}")
    end
  end
end
