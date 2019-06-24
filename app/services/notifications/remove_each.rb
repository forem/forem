module Notifications
  class RemoveEach
    # notifiable_collection_ids: an array of
    # notifiable objects ids (eg mention)
    def initialize(notifiable_collection_ids)
      @notifiable_collection_ids = notifiable_collection_ids
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      Notification.where(
        notifiable_id: notifiable_collection_ids,
        notifiable_type: "Mention",
      ).delete_all
    end

    private

    attr_reader :notifiable_collection_ids
  end
end
