module Streams
  class TwitchWebhookRegistrationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 10

    def perform(user_id, service = TwitchWebhook::Register)
      user = User.find_by(id: user_id)
      return if user.blank? || user.twitch_username.blank?

      service.call(user)
    end
  end
end
