class RateLimitChecker
  attr_reader :user, :action

  # Values are seconds until a user can retry
  RETRY_AFTER = {
    article_update: 30,
    image_upload: 30,
    published_article_creation: 30,
    organization_creation: 300
  }.with_indifferent_access.freeze

  CONFIGURABLE_RATES = {
    rate_limit_follow_count_daily: { min: 0, placeholder: 500, description: "The number of users a person can follow daily" },
    rate_limit_comment_creation: { min: 0, placeholder: 9, description: "The number of comments a user can create within 30 seconds" },
    rate_limit_published_article_creation: { min: 0, placeholder: 9, description: "The number of articles a user can create within 30 seconds" },
    rate_limit_image_upload: { min: 0, placeholder: 9, description: "The number of images a user can upload within 30 seconds" },
    rate_limit_email_recipient: { min: 0, placeholder: 5, description: "The number of emails we send to a user within 2 minutes" },
    rate_limit_organization_creation: { min: 1, placeholder: 1, description: "The number of organizations a user can create within a 5 minute period" }
  }.freeze

  def initialize(user = nil)
    @user = user
  end

  class LimitReached < StandardError
    attr_reader :retry_after

    def initialize(retry_after)
      @retry_after = retry_after
    end

    def message
      "Rate limit reached, try again in #{retry_after} seconds"
    end
  end

  def check_limit!(action)
    return unless limit_by_action(action)

    retry_after = RateLimitChecker::RETRY_AFTER[action]
    raise RateLimitChecker::LimitReached, retry_after
  end

  def limit_by_action(action)
    check_method = "check_#{action}_limit"
    result = respond_to?(check_method, true) ? send(check_method) : false

    if result
      @action = action
      log_to_datadog
    end
    result
  end

  def track_limit_by_action(action)
    cache_key = "#{@user.id}_#{action}"
    expires_in = RETRY_AFTER[action].seconds
    Rails.cache.increment(cache_key, 1, expires_in: expires_in)
  end

  def limit_by_email_recipient_address(address)
    # This is related to the recipient, not the "user" initiator, like in action.
    EmailMessage.where(to: address).where("sent_at > ?", 2.minutes.ago).size >
      SiteConfig.rate_limit_email_recipient
  end

  private

  def check_comment_creation_limit
    user.comments.where("created_at > ?", 30.seconds.ago).size >
      SiteConfig.rate_limit_comment_creation
  end

  def check_published_article_creation_limit
    user.articles.published.where("created_at > ?", 30.seconds.ago).size >
      SiteConfig.rate_limit_published_article_creation
  end

  def check_organization_creation_limit
    Rails.cache.read("#{user.id}_organization_creation").to_i >=
      SiteConfig.rate_limit_organization_creation
  end

  def check_image_upload_limit
    Rails.cache.read("#{user.id}_image_upload").to_i >
      SiteConfig.rate_limit_image_upload
  end

  def check_article_update_limit
    Rails.cache.read("#{user.id}_article_update").to_i >
      SiteConfig.rate_limit_article_update
  end

  def check_follow_account_limit
    user_today_follow_count > SiteConfig.rate_limit_follow_count_daily
  end

  def user_today_follow_count
    following_users_count = user.following_users_count
    return following_users_count if following_users_count < SiteConfig.rate_limit_follow_count_daily

    now = Time.zone.now
    user.follows.where(created_at: (now.beginning_of_day..now)).size
  end

  def log_to_datadog
    DatadogStatsClient.increment("rate_limit.limit_reached", tags: ["user:#{user.id}", "action:#{action}"])
  end
end
