module Streams
  class TwitchWebhookRegistrationJob < ApplicationJob
    queue_as :twitch_webhook_registration

    def perform(user_id, service = TwitchWebhook::Register)
      user = User.find_by(id: user_id)
      return if user.blank? || user.twitch_username.blank?

      service.call(user)
    end
  end
end
