class MailchimpBot
  attr_reader :user, :saved_changes, :gibbon

  def initialize(user)
    @user = user
    @saved_changes = user.saved_changes
    @gibbon = Gibbon::Request.new
  end

  def upsert
    return true unless Rails.env.production? || Rails.env.test?
    upsert_to_membership_newsletter
    upsert_to_newsletter
  end

  def upsert_to_newsletter
    # attempt to update email if user changed email addresses
    success = false
    begin
      gibbon.lists(ENV["MAILCHIMP_NEWSLETTER_ID"]).members(target_md5_email).upsert(
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
            EXPERIENCE: user.experience_level || 666,
            COUNTRY: user.shipping_country.to_s,
            STATE: user.shipping_state.to_s,
            POSTAL_ZIP: user.shipping_postal_code.to_s,
          },
        },
      )
      success = true
    rescue Gibbon::MailChimpError => e
      report_error(e)
    end
    success
  end

  def upsert_to_membership_newsletter
    return false unless a_sustaining_member?
    success = false
    # !!! user.monthly_due = 0 ? unsubscibe
    tiers = %i[ triple_unicorn_member
                level_4_member
                level_3_member
                level_2_member
                level_1_member]
    membership = tiers.each { |t| break t if user.has_role?(t) }
    status = user.email_membership_newsletter ? "subscribed" : "unsubscribed"

    begin
      gibbon.lists(ENV["MAILCHIMP_SUSTAINING_MEMBERS_ID"]).members(target_md5_email).upsert(
        body: {
          email_address: user.email,
          status: status,
          merge_fields: {
            NAME: user.name.to_s,
            USERNAME: user.username.to_s,
            TWITTER: user.twitter_username.to_s,
            GITHUB: user.github_username.to_s,
            IMAGE_URL: user.profile_image_url.to_s,
            MEMBERSHIP: membership.to_s,
          },
        },
      )
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

  def report_error(e)
    logger = Logger.new(STDOUT)
    logger.error(e)
  end

  def target_md5_email
    email = saved_changes["unconfirmed_email"] ? saved_changes["email"][0] : user.email
    md5_email(email)
  end
end
