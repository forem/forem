module Follows
  class CheckCached
    def self.call(follower, followable_type, followable_id)
      new(follower, followable_type, followable_id).call
    end

    def initialize(follower, followable_type, followable_id)
      @follower = follower
      @followable_type = followable_type
      @followable_id = followable_id
    end

    def call
      return false unless follower

      cache_key = "user-#{follower.id}-#{follower.updated_at.rfc3339}/is_following_#{followable_type}_#{followable_id}"
      Rails.cache.fetch(cache_key, expires_in: 20.hours) do
        follower.following?(followable.find(followable_id))
      end
    end

    private

    attr_accessor :follower, :followable_type, :followable_id

    def followable
      case followable_type
      when "Tag", "Organization", "Podcast"
        followable_type.constantize
      else
        User
      end
    end
  end
end
