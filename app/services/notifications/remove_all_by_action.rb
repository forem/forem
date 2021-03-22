module Notifications
  class RemoveAllByAction
    def initialize(notifiable_ids, notifiable_type, action)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      @notifiable_collection = notifiable_type.constantize.where(id: notifiable_ids)
      @action = action
    end

    def self.call(...)
      new(...).call
    end

    def call
      Notification.where(
        notifiable: notifiable_collection,
        action: action,
      ).delete_all
    end

    private

    attr_reader :notifiable_collection, :action
  end
end
