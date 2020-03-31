module Streams
  class TwitchWebhookRegistrationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return if user.blank? || user.twitch_username.blank?

      TwitchWebhook::Register.call(user)
    end
  end
end
