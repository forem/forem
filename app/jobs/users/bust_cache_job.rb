module Users
  class BustCacheJob < ApplicationJob
    queue_as :users_bust_cache

    def perform(user_id, cache_buster = CacheBuster.new)
      user = User.find_by(id: user_id)
      return unless user

      cache_buster.bust_user(user)
    end
  end
end
