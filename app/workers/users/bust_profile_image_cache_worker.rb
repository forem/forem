module Users
  class BustProfileImageCacheWorker < BustCacheBaseWorker
    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      EdgeCache::PurgeByKey.call(user.profile_image_record_key, fallback_paths: user.profile_cache_bust_paths)
    end
  end
end
