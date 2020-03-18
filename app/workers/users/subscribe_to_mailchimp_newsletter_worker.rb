module Users
  class SubscribeToMailchimpNewsletterWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)

      MailchimpBot.new(user).upsert if user
    end
  end
end
