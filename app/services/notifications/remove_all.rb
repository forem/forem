module Notifications
  class RemoveAll
    def initialize(notifiable_id, notifiable_type, action)
      @notifiable_id = notifiable_id
      @notifiable_type = notifiable_type
      @action = action
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      Notification.where(
        notifiable_id: notifiable_id,
        notifiable_type: notifiable_type,
        action: action,
      ).delete_all
    end

    private

    attr_reader :notifiable_id, :notifiable_type, :action
  end
end
