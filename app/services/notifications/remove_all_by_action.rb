module Notifications
  class RemoveAllByAction
    def self.call(...)
      new(...).call
    end

    def initialize(notifiable_ids, notifiable_type, action)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      @notifiable_type = notifiable_type
      @notifiable_ids = notifiable_ids
      @notifiable_collection = notifiable_type.constantize.where(id: notifiable_ids)
      @action = action
    end

    # Its callers remove a post's notifications when the post is unpublished.
    def call
      removed = Notification.where(
        notifiable: notifiable_collection,
        action: action,
      ).delete_all
      return removed unless removed.positive?

      Notifications::SyncEvents.removed(
        notifiable_type: notifiable_type,
        notifiable_ids: notifiable_ids,
        action: action,
        reason: "unpublished",
      )
      removed
    end

    private

    attr_reader :notifiable_type, :notifiable_ids, :notifiable_collection, :action
  end
end
