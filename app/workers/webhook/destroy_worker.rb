module Webhook
  class DestroyWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform(user_id, application_id)
      Webhook::Endpoint.where(user_id: user_id, oauth_application_id: application_id).destroy_all
    end
  end
end
