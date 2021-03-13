module EdgeCache
  class BustUser
    def self.call(user)
      return unless user

      username = user.username

      paths = [
        "/#{username}",
        "/#{username}?i=i",
        "/#{username}/comments",
        "/#{username}/comments?i=i",
        "/#{username}/comments/?i=i",
        "/live/#{username}",
        "/live/#{username}?i=i",
        "/feed/#{username}",
      ]

      cache_bust = EdgeCache::Bust.new
      paths.each { |path| cache_bust.call(path) }
    end
  end
end
