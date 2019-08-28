namespace :twitch do
  desc "Register for Webhooks for all User's Registered with Twitch"
  task wehbook_register_all: :environment do
    User.where.not(twitch_username: nil).find_each do |user|
      Streams::TwitchWebhookRegistrationJob.perform_later(user.id)
    end
  end
end
