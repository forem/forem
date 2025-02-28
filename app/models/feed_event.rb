class FeedEvent < ApplicationRecord
  # These are "optional" mostly so that we can perform validated bulk inserts
  # without triggering article/user validation.
  # Since there are database-level constraints, it's fine to skip the automatic
  # Rails-side association validation (which causes an N+1 query).
  belongs_to :article, optional: true
  belongs_to :user, optional: true
  belongs_to :feed_config, optional: true

  after_save :update_article_counters_and_scores
  after_create_commit :record_field_test_event

  enum category: {
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
  VALID_CONTEXT_TYPES = [
    CONTEXT_TYPE_HOME,
    CONTEXT_TYPE_SEARCH,
    CONTEXT_TYPE_TAG,
    CONTEXT_TYPE_EMAIL,
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

  def self.update_counters_for_articles(article_ids)
    article_ids.each do |article_id|
      update_single_article_counters(article_id)
    end
  end

  def self.update_single_article_counters(article_id, feed_config_id = nil)
    ThrottledCall.perform("article_feed_success_score_#{article_id}", throttle_for: 5.minutes) do
      impressions = FeedEvent.where(article_id: article_id, category: "impression")
      return if impressions.empty?

      clicks = FeedEvent.where(article_id: article_id, category: "click")
      reactions = FeedEvent.where(article_id: article_id, category: "reaction")
      comments = FeedEvent.where(article_id: article_id, category: "comment")
      pageviews = FeedEvent.where(article_id: article_id, category: "extended_pageview")

      # Count the distinct users for impressions and each event type
      distinct_impressions_users = impressions.distinct.pluck(:user_id)
      distinct_clicks_users = clicks.distinct.pluck(:user_id)
      distinct_reactions_users = reactions.distinct.pluck(:user_id)
      distinct_comments_users = comments.distinct.pluck(:user_id)
      distinct_pageviews_users = pageviews.distinct.pluck(:user_id)

      # Calculate score based on distinct users
      reactions_score = distinct_reactions_users.size * REACTION_SCORE_MULTIPLIER
      clicks_score = distinct_clicks_users.size # 1x multiplier for clicks
      comments_score = distinct_comments_users.size * COMMENT_SCORE_MULTIPLIER
      pageviews_score = distinct_pageviews_users.size # 1x multiplier for extended pageviews

      score = (clicks_score + pageviews_score + reactions_score + comments_score).to_f / distinct_impressions_users.size

      # Update the article counters
      Article.where(id: article_id).update_all(
        feed_success_score: score,
        feed_clicks_count: clicks.size,
        feed_impressions_count: impressions.size,
      )

      if feed_config_id
         # We give a higher weight to clicks higher in the position rank when calculating for the success of feedconfig.
        clicks_score = clicks.sum("POWER(2.0/3, article_position - 1)")
        score = (clicks_score + pageviews_score + reactions_score + comments_score).to_f / distinct_impressions_users.size
        FeedConfig.find_by(id: feed_config_id)&.update_column(:feed_success_score, score)
      end
    end
  end

  private

  def update_article_counters_and_scores
    return unless article

    self.class.update_single_article_counters(article_id, feed_config_id)
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
