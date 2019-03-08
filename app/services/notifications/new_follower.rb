# send notifications about the new followers
module Notifications
  class NewFollower
    # def initialize(follow_id, is_read = false)
    def initialize(follow, is_read = false)
      @follow = follow
      @is_read = is_read
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      # follow = Follow.find_by(id: follow.id)
      # return unless follow

      recent_follows = Follow.where(followable_type: follow.followable_type, followable_id: follow.followable_id)
                             .where("created_at > ?", 24.hours.ago).order("created_at DESC")

      notification_params = { action: "Follow" }
      if follow.followable_type == "User"
        notification_params[:user_id] = follow.followable_id
      elsif follow.followable_type == "Organization"
        notification_params[:organization_id] = follow.followable_id
      end

      followers = User.where(id: recent_follows.pluck(:follower_id))
      aggregated_siblings = followers.map { |follower| user_data(follower) }
      if aggregated_siblings.size.zero?
        notification = Notification.find_or_create_by(notification_params).destroy
      else
        json_data = { user: user_data(follow.follower), aggregated_siblings: aggregated_siblings }
        notification = Notification.find_or_create_by(notification_params)
        notification.notifiable_id = recent_follows.first.id
        notification.notifiable_type = "Follow"
        notification.json_data = json_data
        notification.notified_at = Time.current
        notification.read = is_read
        notification.save!
      end
      notification
    end

    private

    attr_reader :follow, :is_read

    def user_data(user)
      {
        id: user.id,
        class: { name: "User" },
        name: user.name,
        username: user.username,
        path: user.path,
        profile_image_90: user.profile_image_90,
        comments_count: user.comments_count,
        created_at: user.created_at
      }
    end
  end
end
