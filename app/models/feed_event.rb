class FeedEvent < ApplicationRecord
  # These are "optional" mostly so that we can perform validated bulk inserts
  # without triggering article/user validation.
  # Since there are database-level constraints, it's fine to skip the automatic
  # Rails-side association validation (which causes an N+1 query).
  belongs_to :article, optional: true
  belongs_to :user, optional: true
  belongs_to :feed_config, optional: true

  after_save :update_article_counters_and_scores
  after_save :create_feed_config_offshoot
  after_create_commit :record_field_test_event

  enum :category, {
    impression: 0,
    click: 1,
    reaction: 2,
    comment: 3,
    extended_pageview: 4
  }

  CONTEXT_TYPE_HOME = "home".freeze
  CONTEXT_TYPE_SEARCH = "search".freeze
  CONTEXT_TYPE_TAG = "tag".freeze
  CONTEXT_TYPE_EMAIL = "email".freeze
  CONTEXT_TYPE_SIDEBAR = "sidebar".freeze
  VALID_CONTEXT_TYPES = [
    CONTEXT_TYPE_HOME,
    CONTEXT_TYPE_SEARCH,
    CONTEXT_TYPE_TAG,
    CONTEXT_TYPE_EMAIL,
    CONTEXT_TYPE_SIDEBAR
  ].freeze
  DEFAULT_TIMEBOX = 5.minutes.freeze

  REACTION_SCORE_MULTIPLIER = 6
  COMMENT_SCORE_MULTIPLIER = 12

  validates :article_position, numericality: { only_integer: true, greater_than: 0 }
  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }, presence: true
  # Since we have disabled association validation, this is handy to filter basic bad data
  validates :article_id, presence: true, numericality: { only_integer: true }
  validates :user_id, numericality: { only_integer: true }, allow_nil: true

  def self.record_journey_for(user, article:, category:)
    return unless %i[reaction comment extended_pageview].include?(category)
    # The latest click can only be on this article if a click on it exists at all.
    # This probe uses the (article_id, user_id, category) index and skips the
    # latest-click lookup, which walks the primary key backwards for users with few clicks.
    return unless where(article: article, user: user, category: :click).exists?

    last_click = where(user: user, category: :click).last
    return unless last_click&.article_id == article.id

    create_with(last_click.slice(:article_position, :context_type, :feed_config_id))
      .find_or_create_by(
        category: category,
        user: user,
        article: article,
      )
  end

  def self.bulk_update_counters_by_article_id(article_ids)
    unique_article_ids = article_ids.uniq
    update_counters_for_articles(unique_article_ids)
  end

  def self.bulk_update_counters_by_feed_config_id(feed_config_ids)
    feed_config_ids.compact.uniq.each do |feed_config_id|
      update_single_feed_config_counters(feed_config_id)
    end
  end

  def self.update_counters_for_articles(article_ids)
    article_ids.each do |article_id|
      update_single_article_counters(article_id)
    end
  end

  def self.update_single_article_counters(article_id)
    ThrottledCall.perform("article_feed_success_score_#{article_id}", throttle_for: 5.minutes) do
      # Total events and distinct users per category in a single pass over the
      # article's events. The NULL flag keeps parity with distinct.pluck(:user_id).size,
      # which counts a NULL user_id as one distinct value.
      totals = {}
      distinct_users = Hash.new(0)
      FeedEvent.where(article_id: article_id).group(:category).pluck(
        :category,
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(DISTINCT user_id) + MAX(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END)"),
      ).each do |category, total, users|
        totals[category] = total
        distinct_users[category] = users
      end
      return unless totals["impression"]

      # Calculate score based on distinct users
      reactions_score = distinct_users["reaction"] * REACTION_SCORE_MULTIPLIER
      clicks_score = distinct_users["click"] # 1x multiplier for clicks
      comments_score = distinct_users["comment"] * COMMENT_SCORE_MULTIPLIER
      pageviews_score = distinct_users["extended_pageview"] # 1x multiplier for extended pageviews

      score = (clicks_score + pageviews_score + reactions_score + comments_score).to_f / distinct_users["impression"]

      # Update the article counters
      Article.where(id: article_id).update_all(
        feed_success_score: score,
        feed_clicks_count: totals.fetch("click", 0),
        feed_impressions_count: totals["impression"],
      )
    end
  end

  def self.update_single_feed_config_counters(feed_config_id, throttle_key_suffix: nil)
    throttle_key = ["feed_config_feed_success_score", feed_config_id, throttle_key_suffix].compact.join("_")
    executed = false
    impressions_total = 0

    ThrottledCall.perform(throttle_key, throttle_for: 5.minutes) do
      executed = true
      # Total events, distinct users, and position-weighted click sum per category
      # in a single pass over the feed config's events. The NULL flag keeps parity
      # with distinct.pluck(:user_id).size, which counts a NULL user_id as one distinct value.
      totals = {}
      distinct_users = Hash.new(0)
      clicks_score = 0.0
      FeedEvent.where(feed_config_id: feed_config_id).group(:category).pluck(
        :category,
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(DISTINCT user_id) + MAX(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(POWER(2.0/3, article_position - 1))"),
      ).each do |category, total, users, position_weighted_sum|
        totals[category] = total
        distinct_users[category] = users
        clicks_score = position_weighted_sum.to_f if category == "click"
      end
      impressions_total = totals["impression"].to_i
      next if impressions_total.zero?

      # Calculate score based on distinct users
      reactions_score = distinct_users["reaction"] * REACTION_SCORE_MULTIPLIER * 2
      comments_score = distinct_users["comment"] * COMMENT_SCORE_MULTIPLIER * 2
      pageviews_score = distinct_users["extended_pageview"] # 1x multiplier for extended pageviews

      score = (clicks_score + pageviews_score + reactions_score + comments_score).to_f / distinct_users["impression"]

      # Update the feed config counters
      FeedConfig.where(id: feed_config_id).update_all(
        feed_success_score: score,
        feed_impressions_count: impressions_total,
      )
    end

    return unless executed && impressions_total < FeedConfig::LOW_IMPRESSION_COUNT

    Rails.cache.delete(format(ThrottledCall::KEY_TEMPLATE, key: throttle_key))
  end

  private

  def update_article_counters_and_scores
    self.class.update_single_article_counters(article_id) if article_id
    return unless feed_config_id

    if impression?
      self.class.update_single_feed_config_counters(feed_config_id)
    else
      self.class.update_single_feed_config_counters(feed_config_id, throttle_key_suffix: category)
    end
  end

  def create_feed_config_offshoot
    # Any time we get qualifying engagement on a proven config, branch off a slightly modified feed config
    return unless feed_config && !feed_config.archived?
    return if feed_config.feed_impressions_count < FeedConfig::LOW_IMPRESSION_COUNT

    target_bucket = offshoot_targeting_bucket
    return unless offshoot_trigger_category?(target_bucket)

    ThrottledCall.perform("create_feed_config_offshoot_#{target_bucket}", throttle_for: 5.minutes) do
      feed_config.create_slightly_modified_clone!(
        user: user,
        context_type: context_type,
        targeting_bucket: target_bucket,
      )
    end
  end

  def offshoot_targeting_bucket
    if context_type == CONTEXT_TYPE_EMAIL || feed_config.targeting_bucket == FeedConfig::BUCKET_DIGEST
      FeedConfig::BUCKET_DIGEST
    elsif user.present?
      FeedConfig.targeting_bucket_for(user, context_type: context_type)
    elsif FeedConfig::NON_ALL_TARGETING_BUCKETS.include?(feed_config.targeting_bucket)
      feed_config.targeting_bucket
    else
      FeedConfig::BUCKET_FEED_CASUAL_USER
    end
  end

  def offshoot_trigger_category?(target_bucket)
    case target_bucket
    when FeedConfig::BUCKET_DIGEST
      %w[click extended_pageview reaction comment].include?(category)
    when FeedConfig::BUCKET_FEED_NEW_USER, FeedConfig::BUCKET_FEED_CASUAL_USER
      %w[reaction comment extended_pageview].include?(category)
    else
      %w[reaction comment].include?(category)
    end
  end

  # @see AbExperiment::GoalConversionHandler
  def record_field_test_event
    return if FieldTest.config["experiments"].nil?
    return if category.to_s == "impression"
    return unless user_id
    return unless context_type == CONTEXT_TYPE_EMAIL # We are only doing this for email at the moment

    Users::RecordFieldTestEventWorker
      .perform_async(user_id, AbExperiment::GoalConversionHandler::USER_CREATES_EMAIL_FEED_EVENT_GOAL)
  end
end
