module Notifications
  module AdminNotifications
    # Creates one notification for each existing user in user_ids, all anchored
    # to a new AdminNotification, and reports them as one sync event.
    class Send
      def self.call(...)
        new(...).call
      end

      # @param user_ids [Array<Integer>] at most MAX_RECIPIENTS
      # @param content [Hash] "title", "body", "url"
      # @param actor [User, nil] whose avatar the notification shows
      # @return [Array(AdminNotification, Hash{Integer => Integer})] the anchor
      #   and each created notification id by user id; [nil, {}] when no user exists
      def initialize(user_ids:, content:, actor: nil)
        @user_ids = user_ids
        @content = content
        @actor = actor
      end

      def call
        recipient_ids = User.where(id: user_ids).ids
        return [nil, {}] if recipient_ids.empty?

        now = Time.current
        json_data = AdminNotifications.json_data(content, actor: actor)
        anchor, rows = ActiveRecord::Base.transaction do
          anchor = AdminNotification.create!
          attributes = recipient_ids.map do |user_id|
            { user_id: user_id, notifiable_type: NOTIFIABLE_TYPE, notifiable_id: anchor.id, action: nil,
              json_data: json_data, read: false, notified_at: now, created_at: now, updated_at: now }
          end
          [anchor, Notification.insert_all(attributes, returning: %i[id user_id])]
        end

        ids = rows.to_h { |row| [row["user_id"], row["id"]] }
        SyncEvents.sent(
          Notification.new(user_id: ids.keys.first, notifiable_type: NOTIFIABLE_TYPE, notifiable_id: anchor.id,
                           json_data: json_data, notified_at: now),
          recipients: ids,
        )
        [anchor, ids]
      end

      private

      attr_reader :user_ids, :content, :actor
    end
  end
end
