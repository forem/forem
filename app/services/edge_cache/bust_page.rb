module EdgeCache
  class BustPage < Bust
    def self.call(slug)
      return unless slug

      bust("/page/#{slug}")
      bust("/page/#{slug}?i=i")
      bust("/#{slug}")
      bust("/#{slug}?i=i")
    end
  end
end
