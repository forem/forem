module Users
  class BustCacheJob < ApplicationJob
    queue_as :users_bust_cache

    def perform(user_id, cache_buster = CacheBuster.new)
      user = User.find_by(id: user_id)

      cache_buster.bust_user(user) if user
    end
  end
end
