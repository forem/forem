module EdgeCache
  class BustTag < Bust
    def self.call(tag)
      return unless tag

      tag.purge

      bust("/t/#{tag.name}")
      bust("/t/#{tag.name}?i=i")
      bust("/t/#{tag.name}/?i=i")
      bust("/t/#{tag.name}/")
      bust("/tags")
    end
  end
end
