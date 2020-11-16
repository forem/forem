module ActsAsFollower #:nodoc:
  module FollowScopes

    # returns Follow records where follower is the record passed in.
    def for_follower(follower)
      where(follower_id: follower.id, follower_type: parent_class_name(follower))
    end

    # returns Follow records where followable is the record passed in.
    def for_followable(followable)
      where(followable_id: followable.id, followable_type: parent_class_name(followable))
    end

    # returns Follow records where follower_type is the record passed in.
    def for_follower_type(follower_type)
      where(follower_type: follower_type)
    end

    # returns Follow records where followeable_type is the record passed in.
    def for_followable_type(followable_type)
      where(followable_type: followable_type)
    end

    # returns Follow records from past 2 weeks with default parameter.
    def recent(from)
      where(["created_at > ?", (from || 2.weeks.ago).to_s(:db)])
    end

    # returns Follow records in descending order.
    def descending
      order("follows.created_at DESC")
    end

    # returns unblocked Follow records.
    def unblocked
      where(blocked: false)
    end

    # returns blocked Follow records.
    def blocked
      where(blocked: true)
    end

  end
end
