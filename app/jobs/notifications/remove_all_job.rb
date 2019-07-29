module Notifications
  class RemoveAllJob < ApplicationJob
    queue_as :remove_all_notifications

    def perform(notifiable_collection_ids, service = Notifications::RemoveAll)
      return unless notifiable_collection_ids.any?

      service.call(notifiable_collection_ids)
    end
  end
end
