module Notifications
  class RemoveAll
    def initialize(notifiable_ids, notifiable_type)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      @notifiable_collection = notifiable_type.constantize.where(id: notifiable_ids)
    end

    def self.call(...)
      new(...).call
    end

    def call
      Notification.where(
        notifiable: notifiable_collection,
      ).delete_all
    end

    private

    attr_reader :notifiable_collection
  end
end
