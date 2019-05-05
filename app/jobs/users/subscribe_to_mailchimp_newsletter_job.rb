module Users
  class SubscribeToMailchimpNewsletterJob < ApplicationJob
    queue_as :users_subscribe_to_mailchimp_newsletter

    def perform(user_id)
      user = User.find_by(id: user_id)

      MailchimpBot.new(user).upsert if user
    end
  end
end
