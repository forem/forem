module EdgeCache
  class BustUser
    def self.call(user)
      return unless user

      EdgeCache::PurgeByKey.call(user.profile_cache_keys, fallback_paths: user.profile_cache_bust_paths)
    end
  end
end
