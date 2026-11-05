class RateLimitChecker
  attr_reader :user, :action

  # retry_after values are the seconds until a user can retry an action.
  # retry_after_setting names a Settings::RateLimit attribute to read the
  # window from instead, so admins can configure it.
  ACTION_LIMITERS = {
    agent_session_creation: { retry_after: 60 },
    ai_image_generation: { retry_after: 60 },
    api_ai_image_generation: { retry_after_setting: :api_ai_image_generation_window_seconds },
    api_image_upload: { retry_after_setting: :api_image_upload_window_seconds },
    article_update: { retry_after: 30 },
    comment_antispam_creation: { retry_after: 300 },
    comment_creation: { retry_after: 30 },
    feedback_message_creation: { retry_after: 300 },
    flag_appeal_creation: { retry_after: 300 },
    image_upload: { retry_after: 30 },
    listing_creation: { retry_after: 60 },
    mention_antispam_creation: { retry_after: 3600 },
    mention_creation: { retry_after: 3600 },
    organization_creation: { retry_after: 300 },
    published_article_creation: { retry_after: 30 },
    published_article_antispam_creation: { retry_after: 300 },
    reaction_creation: { retry_after: 30 },
    send_email_confirmation: { retry_after: 120 },
    user_subscription_creation: { retry_after: 30 },
    user_update: { retry_after: 30 }
  }.with_indifferent_access.freeze

  def self.extract_other_mentioned_usernames(html, author_username: nil)
    return [] if html.blank? || html.exclude?("mentioned-user")

    usernames = ForemNative.extract_mentioned_usernames(html.to_s) || begin
      doc = Nokogiri::HTML(html.to_s)
      non_liquid = doc.css(".mentioned-user").reject do |tag|
        tag.ancestors(".liquid-comment").any? ||
          tag.ancestors("[class^=ltag]").any? ||
          tag.ancestors("[class*=' ltag']").any?
      end
      non_liquid.map { |link| link.text.delete("@").downcase }
    end

    excluded = author_username.to_s.downcase
    usernames.map { |u| u.to_s.downcase }.uniq.reject { |u| u.blank? || u == excluded }
  end

  def initialize(user = nil)
    @user = user
  end

  class LimitReached < StandardError
    attr_reader :retry_after

    def initialize(retry_after)
      @retry_after = retry_after
    end

    def message
      I18n.t("services.rate_limit_checker.limit_reached", count: retry_after)
    end
  end

  def check_limit!(action)
    return if ApplicationConfig["E2E"]
    return unless limit_by_action(action)

    raise LimitReached, retry_after_for(action)
  end

  # Atomically counts an attempt against the action's limit, raising if it
  # pushes the user over. Unlike check_limit! + track_limit_by_action, this
  # can't be raced by concurrent requests, and it counts failed attempts too,
  # which matters for expensive actions. A limit of 0 blocks every attempt.
  def consume!(action)
    return if ApplicationConfig["E2E"]

    count = track_limit_by_action(action).to_i
    return if count <= action_rate_limit(action)

    @action = action
    log_to_datadog
    raise LimitReached, retry_after_for(action)
  end

  def limit_by_action(action)
    return false if ApplicationConfig["E2E"]

    check_method = "check_#{action}_limit"
    result = respond_to?(check_method, true) ? __send__(check_method) : false

    if result
      @action = action
      log_to_datadog
    end
    result
  end

  def track_limit_by_action(action)
    expires_in = retry_after_for(action).seconds
    Rails.cache.increment(limit_cache_key(action), 1, expires_in: expires_in, raw: true)
  end

  def limit_by_email_recipient_address(address)
    # This is related to the recipient, not the "user" initiator, like in action.
    EmailMessage.where(to: address).where("sent_at > ?", 2.minutes.ago).size >
      Settings::RateLimit.email_recipient
  end

  def trusted_mentioner?
    return false unless user

    user.trusted? ||
      user.auditable? ||
      user.super_moderator? ||
      user.base_subscriber? ||
      user.badge_achievements_count.to_i > 6
  end

  def established_mentioner?
    return false unless user
    return true if trusted_mentioner?

    !Settings::RateLimit.user_considered_new?(user: user) &&
      user.badge_achievements_count.to_i >= 4
  end

  def low_trust_mentioner?
    return false unless user
    return false if established_mentioner?

    !Settings::RateLimit.user_considered_new?(user: user) &&
      user.badge_achievements_count.to_i.between?(1, 3)
  end

  def untrusted_mentioner?
    !established_mentioner? && !low_trust_mentioner?
  end

  def max_mentions_per_post
    max_cap = Settings::RateLimit.mention_creation
    return max_cap if established_mentioner?

    antispam_cap = Settings::RateLimit.mention_antispam_creation
    if low_trust_mentioner?
      [(antispam_cap * 1.5).ceil, max_cap].min
    else
      [antispam_cap, max_cap].min
    end
  end

  def hourly_mention_limit
    if trusted_mentioner?
      Settings::RateLimit.mention_hourly_limit * 3
    elsif established_mentioner?
      Settings::RateLimit.mention_hourly_limit
    elsif low_trust_mentioner?
      Settings::RateLimit.mention_antispam_hourly_limit * 2
    else
      Settings::RateLimit.mention_antispam_hourly_limit
    end
  end

  def mention_rate_limit_reached?(new_mentions_count: 1, exclude_notifiable: nil)
    return false if ApplicationConfig["E2E"]
    return false unless user

    limit = hourly_mention_limit
    reached = (limit <= 0 && new_mentions_count.to_i.positive?) ||
      (recent_mention_count(exclude_notifiable: exclude_notifiable) + new_mentions_count.to_i) > limit

    if reached
      @action = established_mentioner? ? :mention_creation : :mention_antispam_creation
      log_to_datadog
    end
    reached
  end

  def track_mentions(count = 1)
    return if count.to_i <= 0 || user.blank?

    Rails.cache.increment(limit_cache_key(:mention_hourly_count), count.to_i, expires_in: 1.hour, raw: true)
  end

  def recent_mention_count(exclude_notifiable: nil)
    return 0 unless user&.id

    cached_count = if exclude_notifiable&.persisted?
                     0
                   else
                     Rails.cache.read(limit_cache_key(:mention_hourly_count), raw: true).to_i
                   end
    db_count = recent_persisted_mention_count(exclude_notifiable: exclude_notifiable)
    html_count = recent_html_mention_count(exclude_notifiable: exclude_notifiable)
    [cached_count, db_count, html_count].max
  end

  private

  ACTION_LIMITERS.each_key do |action|
    define_method(:"check_#{action}_limit") do
      Rails.cache.read(limit_cache_key(action), raw: true).to_i > action_rate_limit(action)
    end
  end

  # Actions without an ACTION_LIMITERS entry (e.g. comment_creation) have no retry_after.
  def retry_after_for(action)
    config = ACTION_LIMITERS.fetch(action, {})
    return config[:retry_after] unless config.key?(:retry_after_setting)

    Settings::RateLimit.public_send(config[:retry_after_setting])
  end

  def limit_cache_key(action)
    unique_key_component = @user&.id || @user&.ip_address
    raise I18n.t("services.rate_limit_checker.invalid_key") if unique_key_component.blank?

    "#{unique_key_component}_#{action}"
  end

  def action_rate_limit(action)
    Settings::RateLimit.public_send(action)
  end

  def check_comment_creation_limit
    user.comments.where("created_at > ?", 30.seconds.ago).size >
      Settings::RateLimit.comment_creation
  end

  def check_published_article_creation_limit
    # TODO: We should make this time frame configurable.
    user.articles.published.from_subforem.where("created_at > ?", 30.seconds.ago).size >
      Settings::RateLimit.published_article_creation
  end

  def check_published_article_antispam_creation_limit
    # TODO: We should make this time frame configurable.
    user.articles.published.from_subforem.where("created_at > ?", 5.minutes.ago).size >
      Settings::RateLimit.published_article_antispam_creation
  end

  def check_comment_antispam_creation_limit
    # TODO: We should make this time frame configurable.
    user.comments.where(created_at: 5.minutes.ago...).size >
      Settings::RateLimit.comment_antispam_creation
  end

  def check_mention_creation_limit
    recent_mention_count >= Settings::RateLimit.mention_hourly_limit
  end

  def check_mention_antispam_creation_limit
    recent_mention_count >= Settings::RateLimit.mention_antispam_hourly_limit
  end

  def recent_persisted_mention_count(exclude_notifiable: nil)
    comment_scope = user.comments.where("created_at > ?", 1.hour.ago)
    article_scope = user.articles.published.where("published_at > ?", 1.hour.ago)

    if exclude_notifiable&.persisted?
      case exclude_notifiable
      when Comment
        comment_scope = comment_scope.where.not(id: exclude_notifiable.id)
      when Article
        article_scope = article_scope.where.not(id: exclude_notifiable.id)
      end
    end

    Mention.where(created_at: 1.hour.ago..)
      .where(
        "(mentionable_type = 'Comment' AND mentionable_id IN (?)) OR " \
        "(mentionable_type = 'Article' AND mentionable_id IN (?))",
        comment_scope.select(:id),
        article_scope.select(:id),
      ).count
  end

  def recent_html_mention_count(exclude_notifiable: nil)
    comment_scope = user.comments.where("created_at > ?", 1.hour.ago)
      .where("processed_html LIKE ?", "%mentioned-user%")
    article_scope = user.articles.published.where("published_at > ?", 1.hour.ago)
      .where("processed_html LIKE ?", "%mentioned-user%")

    if exclude_notifiable&.persisted?
      case exclude_notifiable
      when Comment
        comment_scope = comment_scope.where.not(id: exclude_notifiable.id)
      when Article
        article_scope = article_scope.where.not(id: exclude_notifiable.id)
      end
    end

    htmls = comment_scope.limit(50).pluck(:processed_html) +
      article_scope.limit(20).pluck(:processed_html)
    htmls.sum do |html|
      self.class.extract_other_mentioned_usernames(html, author_username: user.username).size
    end
  end

  def check_follow_account_limit
    user_today_follow_count > Settings::RateLimit.follow_count_daily
  end

  def user_today_follow_count
    following_users_count = user.following_users_count
    return following_users_count if following_users_count < Settings::RateLimit.follow_count_daily

    now = Time.zone.now
    user.follows.where(created_at: (now.beginning_of_day..now)).size
  end

  def log_to_datadog
    ForemStatsClient.increment("rate_limit.limit_reached", tags: ["user:#{user.id}", "action:#{action}"])
  end
end
