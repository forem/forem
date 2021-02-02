module EdgeCache
  class BustPodcast < Bust
    def self.call(path)
      return unless path

      bust("/#{path}")
    end
  end
end
