# app/workers/emails/drip_email_worker.rb
module Emails
  class DripEmailWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 15

    # Treat nil or zero as default grouping

    def perform
      return unless FeatureFlag.enabled?("onboarding_drip_emails")

      last_drip_day = Email.where(type_of: "onboarding_drip").maximum(:drip_day)
      return unless last_drip_day


      default_onboarding_ids = [nil, Subforem.cached_default_id]

      (1..last_drip_day).each do |drip_day|
        start_time = ((drip_day * 24) + 1).hours.ago
        end_time   = (drip_day * 24).hours.ago

        users = User.where(registered_at: start_time..end_time)

        users.each do |user|
          # skip if unsubscribed or recently emailed
          next unless user.notification_setting.email_newsletter
          next if EmailMessage.where(user: user)
                              .where("sent_at >= ?", 12.hours.ago)
                              .exists?

          # pick template based on user's onboarding_subforem_id
          email_template = if default_onboarding_ids.include?(user.onboarding_subforem_id)
                             Email.where(
                               type_of: "onboarding_drip",
                               drip_day: drip_day,
                               status: "active"
                             )
                             .where(onboarding_subforem_id: default_onboarding_ids)
                             .order(:id)
                             .first
                           else
                             Email.find_by(
                               type_of: "onboarding_drip",
                               drip_day: drip_day,
                               status: "active",
                               onboarding_subforem_id: user.onboarding_subforem_id
                             )
                           end

          next unless email_template

          CustomMailer.with(
            user:       user,
            subject:    email_template.subject,
            content:    email_template.body,
            type_of:    email_template.type_of,
            email_id:   email_template.id
          )
          .custom_email
          .deliver_now
        rescue StandardError => e
          Rails.logger.error("Error sending drip email to user \#{user.id}: \#{e.message}")
        end
      end
    end
  end
end
