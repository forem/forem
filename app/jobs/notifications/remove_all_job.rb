module Notifications
  class RemoveAllJob < ApplicationJob
    queue_as :remove_all_notifications

    def perform(notifiable_id, notifiable_type, service = Notifications::RemoveAll)
      service.call(notifiable_id, notifiable_type)
    end
  end
end
