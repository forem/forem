module Emails
  class ReengagementPruneWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing, on_conflict: :replace

    INACTIVE_THRESHOLD = 2.years

    def perform(campaign_key, user_ids)
      cutoff = INACTIVE_THRESHOLD.ago

      recipients = EmailReengagementRecipient
        .for_campaign(campaign_key).sent.unconfirmed.not_pruned
        .where(user_id: user_ids)
        .includes(user: :notification_setting)

      recipients.find_each do |recipient|
        user = recipient.user
        next unless user
        next if last_activity_at(user) >= cutoff # re-engaged since send — spare them

        setting = user.notification_setting
        next unless setting # no setting means they aren't receiving these emails anyway

        setting.update!(email_digest_periodic: false, email_newsletter: false)
        recipient.update!(pruned_at: Time.current)
      end
    end

    private

    def last_activity_at(user)
      [user.last_sign_in_at, user.last_presence_at, user.last_comment_at,
       user.last_reacted_at, user.last_article_at].compact.max || Time.at(0).utc
    end
  end
end
