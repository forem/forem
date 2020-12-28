module EdgeCache
  class BustSidebar < Bust
    def self.call
      bust("/sidebars/home")
    end
  end
end
