class RateLimitChecker
  attr_reader :user, :action

  # retry_after values are the seconds until a user can retry an action.
  # retry_after_setting names a Settings::RateLimit attribute to read the
  # window from instead, so admins can configure it.
  ACTION_LIMITERS = {
    agent_session_creation: { retry_after: 60 },
    agent_session_presign: { retry_after_setting: :agent_session_presign_window_seconds },
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

  MENTION_LOCK_MUTEX = Mutex.new

  # Extracts unique mentioned usernames from rendered HTML, excluding the author's own username
  # and mentions embedded inside Liquid tags.
  #
  # @param html [String, nil] rendered HTML containing `.mentioned-user` links
  # @param author_username [String, nil] the author's username to exclude
  # @return [Array<String>] lowercase mentioned usernames
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

  # Returns true if the user is trusted (trusted role, staff/moderator, subscriber, or 7+ badges).
  def trusted_mentioner?
    return false unless user

    user.trusted? ||
      user.auditable? ||
      user.super_moderator? ||
      user.base_subscriber? ||
      user.badge_achievements_count.to_i > 6
  end

  # Returns true if the user is established (trusted or non-new with 4+ badges).
  def established_mentioner?
    return false unless user
    return true if trusted_mentioner?

    !Settings::RateLimit.user_considered_new?(user: user) &&
      user.badge_achievements_count.to_i >= 4
  end

  # Returns true if the user is a low-trust account (non-new with 1-3 badges).
  def low_trust_mentioner?
    return false unless user
    return false if established_mentioner?

    !Settings::RateLimit.user_considered_new?(user: user) &&
      user.badge_achievements_count.to_i.between?(1, 3)
  end

  # Returns true if the user is brand-new or has 0 badges and no elevated roles.
  def untrusted_mentioner?
    !established_mentioner? && !low_trust_mentioner?
  end

  # Returns the maximum number of other users that may be mentioned in a single post or comment.
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

  # Returns the rolling 1-hour mention budget for the user's trust tier.
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

  # Checks whether adding `new_mentions_count` mentions exceeds the user's hourly mention limit.
  # When `reserve: true` is passed, atomically checks and reserves capacity under a lock.
  #
  # @param new_mentions_count [Integer] number of mentions in the record being checked
  # @param exclude_notifiable [Article, Comment, nil] record being created or edited
  # @param reserve [Boolean] whether to atomically reserve capacity when within the limit
  # @return [Boolean] true if the hourly rate limit is reached
  def mention_rate_limit_reached?(new_mentions_count: 1, exclude_notifiable: nil, reserve: false)
    return false if ApplicationConfig["E2E"]
    return false unless user

    if reserve
      return reserve_mentions!(
        new_mentions_count: new_mentions_count,
        exclude_notifiable: exclude_notifiable,
      ).nil?
    end

    limit = hourly_mention_limit
    reached = (limit <= 0 && new_mentions_count.to_i.positive?) ||
      (recent_mention_count(exclude_notifiable: exclude_notifiable) + new_mentions_count.to_i) > limit

    if reached
      @action = established_mentioner? ? :mention_creation : :mention_antispam_creation
      log_to_datadog
    end
    reached
  end

  # Atomically checks whether `new_mentions_count` fits within the user's hourly mention limit
  # and reserves the capacity in cache under a lock so concurrent requests cannot race.
  #
  # @param new_mentions_count [Integer] number of mentions to reserve
  # @param exclude_notifiable [Article, Comment, nil] record being saved
  # @return [Hash, nil] reservation metadata if within limit, or nil if the limit is reached
  def reserve_mentions!(new_mentions_count:, exclude_notifiable: nil)
    return { delta: 0, previous_notifiable_count: 0, count: 0 } if ApplicationConfig["E2E"] || user.blank?

    desired = new_mentions_count.to_i
    with_user_mention_lock do
      limit = hourly_mention_limit
      base_count = recent_mention_count(exclude_notifiable: exclude_notifiable)
      if (limit <= 0 && desired.positive?) || (base_count + desired) > limit
        @action = established_mentioner? ? :mention_creation : :mention_antispam_creation
        log_to_datadog
        return
      end

      previous_notifiable_count = if exclude_notifiable&.persisted?
                                    notifiable_recent_mention_count(exclude_notifiable)
                                  else
                                    0
                                  end
      raw_cached = Rails.cache.read(limit_cache_key(:mention_hourly_count), raw: true).to_i
      target_total = base_count + desired
      delta = [target_total - raw_cached, 0].max
      adjust_hourly_mention_cache(delta) if delta.positive?
      record_notifiable_mentions(exclude_notifiable, desired) if exclude_notifiable&.persisted?

      { delta: delta, previous_notifiable_count: previous_notifiable_count, count: desired }
    end
  end

  # Releases a previously reserved hourly mention delta when a save fails or rolls back.
  #
  # @param reservation [Hash, nil] reservation hash returned by `#reserve_mentions!`
  # @param notifiable [Article, Comment, nil] record whose save rolled back
  def release_mentions(reservation, notifiable: nil)
    return if reservation.blank? || user.blank?

    with_user_mention_lock do
      delta = reservation[:delta].to_i
      adjust_hourly_mention_cache(-delta) if delta.positive?
      if notifiable&.persisted?
        prev = reservation[:previous_notifiable_count].to_i
        write_notifiable_mention_cache(notifiable, prev)
      end
    end
  end

  # Records the hourly mention count contributed by a specific persisted notifiable.
  #
  # @param notifiable [Article, Comment, nil] persisted notifiable
  # @param count [Integer] mention count for the notifiable
  def record_notifiable_mentions(notifiable, count)
    return unless notifiable&.persisted? && user&.id

    current = [notifiable_cached_mention_count(notifiable).to_i, count.to_i].max
    write_notifiable_mention_cache(notifiable, current)
  end

  # Tracks created mentions in the hourly mention cache, reconciling with any per-notifiable reservation.
  #
  # @param count [Integer] number of mentions created
  # @param notifiable [Article, Comment, nil] optional notifiable that produced the mentions
  def track_mentions(count = 1, notifiable: nil)
    return if count.to_i <= 0 || user.blank?

    with_user_mention_lock do
      if notifiable&.persisted?
        previous_cached = notifiable_cached_mention_count(notifiable)
        delta = [count.to_i - previous_cached.to_i, 0].max
        adjust_hourly_mention_cache(delta) if delta.positive?
        record_notifiable_mentions(notifiable, count.to_i)
      else
        adjust_hourly_mention_cache(count.to_i)
      end
    end
  end

  # Returns the user's rolling 1-hour mention count across cache, persisted Mention rows, and recent HTML,
  # excluding only `exclude_notifiable`'s own contribution when editing a persisted record.
  #
  # @param exclude_notifiable [Article, Comment, nil] persisted record to exclude from the existing total
  # @return [Integer]
  def recent_mention_count(exclude_notifiable: nil)
    return 0 unless user&.id

    raw_cached_count = Rails.cache.read(limit_cache_key(:mention_hourly_count), raw: true).to_i
    excluded_count = exclude_notifiable&.persisted? ? notifiable_recent_mention_count(exclude_notifiable) : 0
    cached_count = [raw_cached_count - excluded_count, 0].max
    db_count = recent_persisted_mention_count(exclude_notifiable: exclude_notifiable)
    html_count = recent_html_mention_count(exclude_notifiable: exclude_notifiable)
    [cached_count, db_count, html_count].max
  end

  # Serializes hourly mention checks and reservations per user across threads and database connections.
  def with_user_mention_lock
    return yield unless user&.id

    if MENTION_LOCK_MUTEX.owned?
      lock_user_row_if_persisted
      yield
    else
      MENTION_LOCK_MUTEX.synchronize do
        lock_user_row_if_persisted
        yield
      end
    end
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

  # Checks whether the user has reached the standard hourly mention creation limit.
  def check_mention_creation_limit
    recent_mention_count >= Settings::RateLimit.mention_hourly_limit
  end

  # Checks whether the user has reached the antispam hourly mention creation limit.
  def check_mention_antispam_creation_limit
    recent_mention_count >= Settings::RateLimit.mention_antispam_hourly_limit
  end

  # Acquires a database row-level lock on the user record without reloading in-memory attributes.
  def lock_user_row_if_persisted
    return unless user&.persisted?

    User.where(id: user.id).lock.ids
  end

  # Adjusts the user's hourly mention cache counter by a positive or negative delta.
  def adjust_hourly_mention_cache(delta)
    key = limit_cache_key(:mention_hourly_count)
    if delta.positive?
      Rails.cache.increment(key, delta, expires_in: 1.hour, raw: true)
    elsif delta.negative?
      current = Rails.cache.read(key, raw: true).to_i
      updated = [current + delta, 0].max
      Rails.cache.write(key, updated, expires_in: 1.hour, raw: true)
    end
  end

  # Builds the cache key tracking a specific persisted notifiable's hourly mention contribution.
  def notifiable_mention_cache_key(notifiable)
    "#{limit_cache_key(:mention_hourly_count)}:#{notifiable.class.name}:#{notifiable.id}"
  end

  # Reads the cached hourly mention count for a specific persisted notifiable.
  def notifiable_cached_mention_count(notifiable)
    return unless notifiable&.persisted? && user&.id

    Rails.cache.read(notifiable_mention_cache_key(notifiable), raw: true)
  end

  # Writes the cached hourly mention count for a specific persisted notifiable.
  def write_notifiable_mention_cache(notifiable, count)
    return unless notifiable&.persisted? && user&.id

    Rails.cache.write(notifiable_mention_cache_key(notifiable), [count.to_i, 0].max, expires_in: 1.hour, raw: true)
  end

  # Returns the hourly mention count contributed by `notifiable` alone across cache, Mention rows, and recent HTML.
  def notifiable_recent_mention_count(notifiable)
    return 0 unless notifiable&.persisted? && user&.id

    cached = notifiable_cached_mention_count(notifiable)
    db_mentions = Mention.where(mentionable: notifiable, created_at: 1.hour.ago..).count
    html_mentions = if notifiable_within_recent_hour?(notifiable)
                      self.class.extract_other_mentioned_usernames(
                        notifiable_persisted_html(notifiable),
                        author_username: user.username,
                      ).size
                    else
                      0
                    end

    [cached.to_i, db_mentions, html_mentions].max
  end

  # Returns true if the persisted notifiable falls within the 1-hour recent window.
  def notifiable_within_recent_hour?(notifiable)
    case notifiable
    when Comment
      notifiable.created_at.present? && notifiable.created_at > 1.hour.ago
    when Article
      notifiable.published? && notifiable.published_at.present? && notifiable.published_at > 1.hour.ago
    else
      false
    end
  end

  # Returns the persisted processed_html of a notifiable prior to unsaved in-memory edits.
  def notifiable_persisted_html(notifiable)
    if notifiable.respond_to?(:processed_html_in_database)
      notifiable.processed_html_in_database.to_s
    else
      notifiable.processed_html.to_s
    end
  end

  # Counts persisted Mention rows created in the last hour for the user's comments and articles.
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

  # Counts @-mentions in rendered HTML of the user's comments and articles from the last hour.
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
