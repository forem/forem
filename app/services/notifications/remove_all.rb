module Notifications
  class RemoveAll
    def self.call(...)
      new(...).call
    end

    def initialize(notifiable_ids, notifiable_type)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      @notifiable_type = notifiable_type
      @notifiable_ids = notifiable_ids
    end

    def call
      removed = Notification.where(
        notifiable_type: notifiable_type,
        notifiable_id: notifiable_ids,
      ).delete_all
      return removed unless removed.positive?

      Notifications::SyncEvents.removed(
        notifiable_type: notifiable_type,
        notifiable_ids: notifiable_ids,
        all_actions: true,
        reason: "content_removed",
      )
      removed
    end

    private

    attr_reader :notifiable_type, :notifiable_ids
  end
end
