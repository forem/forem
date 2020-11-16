class FollowChecker
  attr_accessor :follower, :followable_type, :followable_id

  def initialize(follower, followable_type, followable_id)
    @follower = follower
    @followable_type = followable_type
    @followable_id = followable_id
  end

  def cached_follow_check
    return false unless follower

    cache_key = "user-#{follower.id}-#{follower.updated_at.rfc3339}/is_following_#{followable_type}_#{followable_id}"
    Rails.cache.fetch(cache_key, expires_in: 20.hours) do
      followable = case followable_type
                   when "Tag"
                     Tag.find(followable_id)
                   when "Organization"
                     Organization.find(followable_id)
                   when "Podcast"
                     Podcast.find(followable_id)
                   else
                     User.find(followable_id)
                   end
      follower.following?(followable)
    end
  end
end
