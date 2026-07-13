module Emails
  class ReengagementSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing, on_conflict: :replace

    def perform(email_id, campaign_key, user_ids)
      email = Email.find_by(id: email_id)
      return unless email

      Emails::BatchCustomSendWorker.perform_async(
        user_ids, email.subject, email.body, email.type_of, email.id,
        email.default_from_name_based_on_type, campaign_key
      )

      EmailReengagementRecipient
        .for_campaign(campaign_key)
        .where(user_id: user_ids)
        .update_all(sent_at: Time.current, email_id: email.id, updated_at: Time.current)
    end
  end
end
