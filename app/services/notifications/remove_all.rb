module Notifications
  class RemoveAll
    def initialize(notifiable_collection)
      @notifiable_collection = notifiable_collection
    end

    def self.call(*args)
      new(*args).call
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
