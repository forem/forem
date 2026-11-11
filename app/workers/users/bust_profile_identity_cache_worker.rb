module Users
  class BustProfileIdentityCacheWorker < BustCacheBaseWorker
    PROFILE_CACHE_COLUMNS = %i[id username old_username old_old_username].freeze

    def perform(user_id)
      user = User.select(PROFILE_CACHE_COLUMNS).find_by(id: user_id)
      return unless user

      legacy_keys = EdgeCache::LegacySlugRedirectKeys.call(user.username, exclude_user_id: user.id)
      keys = legacy_keys.any? ? [user.profile_identity_record_key, *legacy_keys] : user.profile_identity_record_key
      EdgeCache::PurgeByKey.call(keys, fallback_paths: user.profile_cache_bust_paths)
    end
  end
end
