module Users
  class BustCacheWorker < BustCacheBaseWorker
    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      CacheBuster.bust_user(user)
    end
  end
end
