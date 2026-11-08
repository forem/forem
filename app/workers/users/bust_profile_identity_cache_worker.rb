module Users
  class BustProfileIdentityCacheWorker < BustCacheBaseWorker
    PROFILE_CACHE_COLUMNS = %i[id username old_username old_old_username].freeze

    def perform(user_id)
      user = User.select(PROFILE_CACHE_COLUMNS).find_by(id: user_id)
      return unless user

      EdgeCache::PurgeByKey.call(user.profile_identity_record_key, fallback_paths: user.profile_cache_bust_paths)
      EdgeCache::Bust.call([user.path, *user.previous_username_paths]) if user.previous_username_paths.any?
    end
  end
end
