class RateLimitChecker
  attr_reader :user, :action

  # retry_after values are the seconds until a user can retry an action
  ACTION_LIMITERS = {
    article_update: { retry_after: 30 },
    image_upload: { retry_after: 30 },
    listing_creation: { retry_after: 60 },
    published_article_creation: { retry_after: 30 },
    organization_creation: { retry_after: 300 }
  }.with_indifferent_access.freeze

  CONFIGURABLE_RATES = {
    rate_limit_follow_count_daily: { min: 0, placeholder: 500, description: "The number of users a person can follow daily" },
    rate_limit_comment_creation: { min: 0, placeholder: 9, description: "The number of comments a user can create within 30 seconds" },
    rate_limit_listing_creation: { min: 1, placeholder: 1, description: "The number of listings a user can create in 1 minute" },
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

    retry_after = ACTION_LIMITERS.dig(action, :retry_after)
    raise LimitReached, retry_after
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
    expires_in = ACTION_LIMITERS.dig(action, :retry_after).seconds
    Rails.cache.increment(limit_cache_key(action), 1, expires_in: expires_in)
  end

  def limit_by_email_recipient_address(address)
    # This is related to the recipient, not the "user" initiator, like in action.
    EmailMessage.where(to: address).where("sent_at > ?", 2.minutes.ago).size >
      SiteConfig.rate_limit_email_recipient
  end

  private

  ACTION_LIMITERS.each_key do |action|
    define_method("check_#{action}_limit") do
      Rails.cache.read(limit_cache_key(action)).to_i > action_rate_limit(action)
    end
  end

  def limit_cache_key(action)
    "#{@user.id}_#{action}"
  end

  def action_rate_limit(action)
    SiteConfig.public_send("rate_limit_#{action}")
  end

  def check_comment_creation_limit
    user.comments.where("created_at > ?", 30.seconds.ago).size >
      SiteConfig.rate_limit_comment_creation
  end

  def check_published_article_creation_limit
    user.articles.published.where("created_at > ?", 30.seconds.ago).size >
      SiteConfig.rate_limit_published_article_creation
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
