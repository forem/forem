module Emails
  class ReengagementPruneWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing, on_conflict: :replace

    INACTIVE_THRESHOLD = 2.years

    def perform(user_ids)
      cutoff = INACTIVE_THRESHOLD.ago

      User.where(id: user_ids).includes(:notification_setting).find_each do |user|
        setting = user.notification_setting
        next unless setting # no setting means they aren't receiving these emails anyway
        next if setting.email_reengagement_confirmed_at.present? || setting.email_reengagement_pruned_at.present?
        next if last_activity_at(user) >= cutoff # re-engaged since the ask — spare them

        setting.update!(email_digest_periodic: false,
                        email_newsletter: false,
                        email_reengagement_pruned_at: Time.current)
      end
    end

    private

    def last_activity_at(user)
      User::ACTIVITY_TIMESTAMP_KEYS.filter_map { |key| user.public_send(key) }.max || Time.at(0).utc
    end
  end
end
