module Notifications
  class RemoveAllByAction
    def initialize(notifiable, action)
      @notifiable = notifiable
      @action = action
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      Notification.where(
        notifiable: notifiable,
        action: action,
      ).delete_all
    end

    private

    attr_reader :notifiable, :action
  end
end
