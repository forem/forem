module Users
  class SubscribeToMailchimpNewsletterWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executed

    def perform(user_id)
      user = User.find_by(id: user_id)

      Mailchimp::Bot.new(user).upsert if user
    end
  end
end
