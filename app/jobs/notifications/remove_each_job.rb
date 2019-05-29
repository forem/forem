module Notifications
  class RemoveEachJob < ApplicationJob
    queue_as :remove_each_notifications

    def perform(notifiable_collection_ids, service = Notifications::RemoveEach)
      return unless notifiable_collection_ids.any?

      service.call(notifiable_collection_ids)
    end
  end
end
