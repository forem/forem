module Mentions
  # This worker is currently only used to create mentions on comments.
  class CreateAllWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 10

    def perform(notifiable_id, notifiable_type)
      return if ["Comment"].none?(notifiable_type)

      notifiable = notifiable_type.constantize.find_by(id: notifiable_id)
      Mentions::CreateAll.call(notifiable) if notifiable
    end
  end
end
