module EdgeCache
  class BustUser
    def self.call(user)
      return unless user

      EdgeCache::PurgeByKey.call(user.profile_cache_keys, fallback_paths: user.profile_cache_bust_paths)
      cutover_paths = [
        ("/#{user.old_username}" if user.old_username.present?),
        ("/#{user.old_old_username}" if user.old_old_username.present?),
      ].compact
      EdgeCache::CutoverUrlBust.call(cutover_paths) if cutover_paths.any?
    end
  end
end
