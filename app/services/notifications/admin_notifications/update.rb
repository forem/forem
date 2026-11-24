module Notifications
  module AdminNotifications
    # Edits one recipient's admin notification in place. It stays where it is in
    # the list and keeps its read state.
    class Update
      def self.call(...)
        new(...).call
      end

      # @param notification [Notification] an admin notification
      # @param changes [Hash] any of "title", "body", "url"; a nil body or url clears it
      def initialize(notification, changes)
        @notification = notification
        @changes = changes
      end

      def call
        data = notification.json_data.deep_dup
        data["admin_notification"] = data.fetch("admin_notification", {}).merge(changes.slice(*CONTENT_KEYS)).compact
        notification.update!(json_data: data)

        SyncEvents.updated(notification, recipients: { notification.user_id => notification.id })
        notification
      end

      private

      attr_reader :notification, :changes
    end
  end
end
