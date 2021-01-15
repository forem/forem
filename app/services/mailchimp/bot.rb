module Mailchimp
  class Bot
    attr_reader :user, :saved_changes, :gibbon

    def initialize(user)
      @user = user
      @saved_changes = user.saved_changes
      Gibbon::Request.api_key = SiteConfig.mailchimp_api_key
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
        gibbon.lists(SiteConfig.mailchimp_newsletter_id).members(target_md5_email).upsert(
          body: {
            email_address: user.email,
            status: user.email_newsletter ? "subscribed" : "unsubscribed",
            merge_fields: {
              NAME: user.name.to_s,
              USERNAME: user.username.to_s,
              TWITTER: user.twitter_username.to_s,
              GITHUB: user.github_username.to_s,
              IMAGE_URL: user.profile_image_url.to_s,
              ARTICLES: user.articles.size,
              COMMENTS: user.comments.size,
              ONBOARD_PK: user.onboarding_package_requested.to_s,
              EXPERIENCE: user.experience_level || 666
            }
          },
        )

        success = true
      rescue Gibbon::MailChimpError => e
        # If user was previously subscribed, set their status to "pending"
        return resubscribe_to_newsletter if previously_subcribed?(e)

        report_error(e)
      end
      success
    end

    def resubscribe_to_newsletter
      success = false

      begin
        gibbon.lists(SiteConfig.mailchimp_newsletter_id).members(target_md5_email).upsert(
          body: { status: "pending" },
        )
        success = true
      rescue Gibbon::MailChimpError => e
        report_error(e)
      end
      success
    end

    def manage_community_moderator_list
      return false unless user.has_role?(:trusted)

      success = false
      status = user.email_community_mod_newsletter ? "subscribed" : "unsubscribed"
      begin
        gibbon.lists(SiteConfig.mailchimp_community_moderators_id).members(target_md5_email).upsert(
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
      return false unless user.tag_moderator?

      success = false

      tag_ids = user.roles.where(name: "tag_moderator").pluck(:resource_id)
      tag_names = Tag.where(id: tag_ids).pluck(:name)

      status = user.email_tag_mod_newsletter ? "subscribed" : "unsubscribed"

      begin
        gibbon.lists(SiteConfig.mailchimp_tag_moderators_id).members(target_md5_email).upsert(
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

    def unsub_sustaining_member
      return unless user.tag_moderator?

      gibbon.lists(SiteConfig.mailchimp_tag_moderators_id).members(target_md5_email).update(
        body: {
          status: "unsubscribed"
        },
      )
    end

    def unsub_community_mod
      return unless user.has_role?(:trusted)

      gibbon.lists(SiteConfig.mailchimp_community_moderators_id).members(target_md5_email).update(
        body: {
          status: "unsubscribed"
        },
      )
    end

    def unsub_tag_mod
      return unless a_sustaining_member?

      gibbon.lists(SiteConfig.mailchimp_sustaining_members_id).members(target_md5_email).update(
        body: {
          status: "unsubscribed"
        },
      )
    end

    def unsubscribe_all_newsletters
      success = false
      begin
        gibbon.lists(SiteConfig.mailchimp_newsletter_id).members(target_md5_email).update(
          body: {
            status: "unsubscribed"
          },
        )
        unsub_tag_mod
        unsub_sustaining_member
        unsub_community_mod
        success = true
      rescue Gibbon::MailChimpError => e
        report_error(e)
      end
      success
    end

    private

    def a_sustaining_member?
      # Reasoning for including => saved_changes["monthly_dues"]
      # Is that mailchimp should be updated if a user decides to
      # unsubscribes
      user.monthly_dues.positive? || saved_changes["monthly_dues"]
    end

    def md5_email(email)
      Digest::MD5.hexdigest(email.downcase)
    end

    def report_error(exception)
      Rails.logger.error(exception)
      DatadogStatsClient.increment("mailchimp.errors",
                                   tags: ["action:failed", "user_id:#{user.id}", "source:gibbon-gem"])
    end

    def target_md5_email
      email = saved_changes["unconfirmed_email"] ? saved_changes["email"][0] : user.email
      md5_email(email)
    end

    def previously_subcribed?(error)
      error.title.include?("Member In Compliance State")
    end
  end
end
