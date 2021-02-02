module EdgeCache
  class BustUser < Bust
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

      paths.each { |path| bust(path) }
    end
  end
end
