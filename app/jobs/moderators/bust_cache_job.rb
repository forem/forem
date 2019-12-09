module Moderators
  class BustCacheJob < ApplicationJob
    queue_as :moderators_bust_cache

    def perform(user_id, cache_buster = CacheBuster)
      user = User.find_by(id: user_id)
      return unless user

      cache_buster.bust("/#{user.old_username}")
    end
  end
end
