class FollowChecker

  attr_accessor :follower, :followable_type, :followable_id

  def initialize(follower, followable_type, followable_id)
    @follower = follower
    @followable_type = followable_type
    @followable_id = followable_id
  end

  def cached_follow_check
    Rails.cache.fetch("user-#{follower.id}-#{follower.updated_at}/is_following_#{followable_type}_#{followable_id}", expires_in: 100.hours) do
      if followable_type == "Tag"
        followable = Tag.find(followable_id)
      elsif followable_type == "Organization"
        followable = Organization.find(followable_id)
      else
        followable = User.find(followable_id)
      end
      follower.following?(followable)
    end
  end
end
