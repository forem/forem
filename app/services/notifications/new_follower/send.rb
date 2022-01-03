# send notifications about the new followers
module Notifications
  module NewFollower
    class Send
      # @param follow_data [Hash]
      #   * :followable_id [Integer]
      #   * :followable_type [String] - "User" or "Organization"
      #   * :follower_id [Integer] - user id
      def initialize(follow_data, is_read: false)
        # we explicitly symbolize_keys because FollowData.new will fail otherwise with an error of
        # ":followable_id is missing in Hash input". FollowData expects a symbol, not a string.
        follow_data.symbolize_keys!
        follow_data = FollowData.new(follow_data) unless follow_data.is_a?(FollowData)
        @followable_id = follow_data.followable_id # fetch(:followable_id)
        @followable_type = follow_data.followable_type # fetch(:followable_type)
        @follower_id = follow_data.follower_id # fetch(:follower_id)
        @is_read = is_read
      end

      delegate :user_data, to: Notifications

      def self.call(...)
        new(...).call
      end

      def call
        recent_follows = Follow.where(followable_type: followable_type, followable_id: followable_id)
          .where("created_at > ?", 24.hours.ago).order(created_at: :desc)

        notification_params = { action: "Follow" }
        case followable_type
        when "User"
          notification_params[:user_id] = followable_id
        when "Organization"
          notification_params[:organization_id] = followable_id
        end

        followers = User.where(id: recent_follows.select(:follower_id))
        aggregated_siblings = followers.map { |follower| user_data(follower) }
        if aggregated_siblings.size.zero?
          notification = Notification.find_by(notification_params)&.destroy
        else
          json_data = { user: user_data(follower), aggregated_siblings: aggregated_siblings }
          notification = Notification.find_or_initialize_by(notification_params)

          # we explicitly load the correct follow, to avoid incurring in the possibility of
          # two different follows created at the same time
          notifiable_follow = recent_follows.detect { |f| f.follower_id == @follower_id }

          # if this method is called after a ".stop_following" the follower_id won't be
          # present, hence, we load the most recent
          notifiable_follow ||= recent_follows.first

          notification.notifiable_id = notifiable_follow.id
          notification.notifiable_type = "Follow"

          notification.json_data = json_data
          notification.notified_at = Time.current
          notification.read = is_read
          notification.save!
        end
        notification
      end

      private

      attr_reader :followable_id, :followable_type, :follower_id, :is_read

      def follower
        User.find(follower_id)
      end
    end
  end
end
