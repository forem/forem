namespace :twitch do
  desc "Register for Webhooks for all User's Registered with Twitch"
  task wehbook_register_all: :environment do
    User.where.not(twitch_username: nil).find_each do |user|
      Streams::TwitchWebhookRegistrationWorker.perform_async(user.id)
    end
  end
end
