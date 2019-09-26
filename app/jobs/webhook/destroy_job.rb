module Webhook
  class DestroyJob < ApplicationJob
    queue_as :webhook_destroy

    def perform(user_id:, application_id:)
      Webhook::Endpoint.where(user_id: user_id, oauth_application_id: application_id).destroy_all
    end
  end
end
