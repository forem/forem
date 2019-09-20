module Notifications
  class RemoveAllByAction
    def initialize(notifiable_id, notifiable_type, action)
      @notifiable_collection = notifiable_type.constantize.where(id: notifiable_id)
      @action = action
    end

    def self.call(*args)
      new(*args).call
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
