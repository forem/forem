module Users
  class BustCacheJob < ApplicationJob
    queue_as :users_bust_cache

    def perform(user_id, cache_buster = CacheBuster.new)
      user = User.find_by(id: user_id)

      cache_buster.bust("/#{user.username}") if user
      cache_buster.bust("/#{user.username}?i=i") if user
      cache_buster.bust("/live/#{user.username}") if user
      cache_buster.bust("/live/#{user.username}?i=i") if user
      cache_buster.bust("/feed/#{user.username}") if user
    end
  end
end
