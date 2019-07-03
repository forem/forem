module Mentions
  class CreateAllJob < ApplicationJob
    queue_as :mentions_create_all

    def perform(notifiable_id, notifiable_type)
      return if ["Comment"].none?(notifiable_type)

      notifiable = notifiable_type.constantize.find_by(id: notifiable_id)
      Mentions::CreateAll.call(notifiable) if notifiable
    end
  end
end
