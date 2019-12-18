class FollowChecker
  attr_accessor :follower, :followable_type, :followable_id

  def initialize(follower, followable_type, followable_id)
    @follower = follower
    @followable_type = followable_type
    @followable_id = followable_id
  end

  def cached_follow_check
    return false unless follower

    Rails.cache.fetch("user-#{follower.id}-#{follower.updated_at.rfc3339}/is_following_#{followable_type}_#{followable_id}", expires_in: 20.hours) do
      followable = if followable_type == "Tag"
                     Tag.find(followable_id)
                   elsif followable_type == "Organization"
                     Organization.find(followable_id)
                   elsif followable_type == "Podcast"
                     Podcast.find(followable_id)
                   else
                     User.find(followable_id)
                   end
      follower.following?(followable)
    end
  end
end
