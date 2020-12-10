module EdgeCache
  class BustEvents < Bust
    def self.call
      bust("/events")
      bust("/events?i=i")
    end
  end
end
