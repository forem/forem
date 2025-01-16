# app/workers/emails/enqueue_custom_batch_send_worker.rb
module Emails
  class EnqueueCustomBatchSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 15

    BATCH_SIZE = Rails.env.production? ? 1000 : 10

    def perform(email_id)
      email = Email.find_by(id: email_id)
      return unless email
  
      user_scope = if email.audience_segment
                     email.audience_segment.users
                          .registered
                          .joins(:notification_setting)
                          .without_role(:suspended)
                          .without_role(:spam)
                          .where(notification_setting: { email_newsletter: true })
                          .where.not(email: "")
                   else
                     User.registered
                         .joins(:notification_setting)
                         .without_role(:suspended)
                         .without_role(:spam)
                         .where(notification_setting: { email_newsletter: true })
                         .where.not(email: "")
                   end

      # Only scope further if targeted_tags is present
      if email.targeted_tags.present?
        user_scope = user_scope.following_tags(email.targeted_tags)
      end

      user_scope.find_in_batches(batch_size: BATCH_SIZE) do |users_batch|
        Emails::BatchCustomSendWorker.perform_async(
          users_batch.map(&:id),
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
      end
    end
  end
end
