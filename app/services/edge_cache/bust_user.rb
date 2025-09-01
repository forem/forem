module EdgeCache
  class BustUser
    def self.call(user)
      return unless user

      user.purge
      username = user.username
      user_id = user.id
      paths = [
        "/api/users/#{user_id}",
      ]

      cache_bust = EdgeCache::Bust.new
      paths.each { |path| cache_bust.call(path) }
    end
  end
end
