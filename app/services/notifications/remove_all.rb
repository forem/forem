module Notifications
  class RemoveAll
    def initialize(notifiable_ids, notifiable_type)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      @notifiable_type = notifiable_type
      @notifiable_ids = notifiable_ids
    end

    def self.call(...)
      new(...).call
    end

    def call
      Notification.where(
        notifiable_type: notifiable_type,
        notifiable_id: notifiable_ids,
      ).delete_all
    end

    private

    attr_reader :notifiable_type, :notifiable_ids
  end
end
