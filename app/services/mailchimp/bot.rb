module Mailchimp
  class Bot
    attr_reader :user, :saved_changes, :gibbon

    def initialize(user)
      @user = user
      @saved_changes = user.saved_changes
      Gibbon::Request.api_key = Settings::General.mailchimp_api_key
      Gibbon::Request.timeout = 15
      @gibbon = Gibbon::Request.new
    end

    def upsert
      return true unless Rails.env.production? || Rails.env.test?

      manage_community_moderator_list
      manage_tag_moderator_list
      upsert_to_newsletter
    end

    def upsert_to_newsletter
      # attempt to update email if user changed email addresses
      success = false
      begin
        gibbon.lists(Settings::General.mailchimp_newsletter_id).members(target_md5_email).upsert(
          body: {
            email_address: user.email,
            status: user.notification_setting.email_newsletter ? "subscribed" : "unsubscribed",
            merge_fields: {
              NAME: user.name.to_s,
              USERNAME: user.username.to_s,
              TWITTER: user.twitter_username.to_s,
              GITHUB: user.github_username.to_s,
              IMAGE_URL: user.profile_image_url.to_s,
              ARTICLES: user.articles.size,
              COMMENTS: user.comments.size,
              ONBOARD_PK: user.onboarding_package_requested.to_s,
              EXPERIENCE: user.setting.experience_level || 666
            }
          },
        )

        success = true
      rescue Gibbon::GibbonError => e
        report_error(e)
      rescue Gibbon::MailChimpError => e
        return resubscribe_as_pending if previously_subscribed?(e)

        report_error(e)
      end
      success
    end

    def resubscribe_as_pending
      success = false

      begin
        gibbon.lists(Settings::General.mailchimp_newsletter_id).members(target_md5_email).upsert(
          body: { status: "pending" },
        )
        success = true
      rescue Gibbon::MailChimpError => e
        report_error(e)
      end
      success
    end

    def manage_community_moderator_list
      return false unless Settings::General.mailchimp_community_moderators_id.present? && user.has_trusted_role?

      success = false
      status = user.notification_setting.email_community_mod_newsletter ? "subscribed" : "unsubscribed"
      begin
        gibbon.lists(Settings::General.mailchimp_community_moderators_id).members(target_md5_email).upsert(
          body: {
            email_address: user.email,
            status: status,
            merge_fields: {
              NAME: user.name.to_s,
              USERNAME: user.username.to_s,
              TWITTER: user.twitter_username.to_s,
              GITHUB: user.github_username.to_s,
              IMAGE_URL: user.profile_image_url.to_s
            }
          },
        )
        success = true
      rescue Gibbon::MailChimpError => e
        report_error(e)
      end
      success
    end

    def manage_tag_moderator_list
      return false unless Settings::General.mailchimp_tag_moderators_id.present? && user.tag_moderator?

      success = false

      tag_names = user.moderator_for_tags_not_cached

      status = user.notification_setting.email_tag_mod_newsletter ? "subscribed" : "unsubscribed"

      begin
        gibbon.lists(Settings::General.mailchimp_tag_moderators_id).members(target_md5_email).upsert(
          body: {
            email_address: user.email,
            status: status,
            merge_fields: {
              NAME: user.name.to_s,
              USERNAME: user.username.to_s,
              TWITTER: user.twitter_username.to_s,
              GITHUB: user.github_username.to_s,
              IMAGE_URL: user.profile_image_url.to_s,
              TAGS: tag_names.join(", ")
            }
          },
        )
        success = true
      rescue Gibbon::MailChimpError => e
        report_error(e)
      end
      success
    end

    def remove_community_mod
      return unless Settings::General.mailchimp_community_moderators_id.present? && user.trusted?

      permanent_delete_from_mailchimp(Settings: General.mailchimp_community_moderators_id)
    end

    def remove_tag_mod
      return unless Settings::General.mailchimp_tag_moderators_id.present? && user.tag_moderator?

      permanent_delete_from_mailchimp(Settings::General.mailchimp_tag_moderators_id)
    end

    def remove_from_mailchimp
      success = false
      begin
        permanent_delete_from_mailchimp(Settings::General.mailchimp_newsletter_id)
        remove_tag_mod
        remove_community_mod
        success = true
      rescue Gibbon::MailChimpError => e
        report_error(e)
      end
      success
    end

    private

    def md5_email(email)
      Digest::MD5.hexdigest(email.downcase)
    end

    def report_error(exception)
      Rails.logger.error(exception)
      ForemStatsClient.increment("mailchimp.errors",
                                 tags: ["action:failed", "user_id:#{user.id}", "source:gibbon-gem"])
    end

    def target_md5_email
      email = saved_changes["unconfirmed_email"] ? saved_changes["email"][0] : user.email
      md5_email(email)
    end

    def permanent_delete_from_mailchimp(list_id)
      gibbon.lists(list_id).members(target_md5_email).actions.delete_permanent.create
    rescue Gibbon::MailChimpError => e
      return if e.status_code == 404

      report_error(e)
    end

    def previously_subscribed?(error)
      error.title.include?("Member In Compliance State")
    end
  end
end
