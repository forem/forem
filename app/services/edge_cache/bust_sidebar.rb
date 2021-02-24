module EdgeCache
  class BustSidebar < Buster
    def self.call
      buster = EdgeCache::Buster.new
      buster.bust("/sidebars/home")
    end
  end
end
