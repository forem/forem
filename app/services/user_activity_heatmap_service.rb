# Aggregates a user's daily activity counts (articles published, comments
# posted, reactions given) over a rolling window for the GitHub-style
# contribution heatmap rendered at the top of /dashboard/analytics.
#
# Only counts a user's *own* activity — owner-scoped, identical for the
# personal-dashboard view. Org-scoped variants are intentionally out of scope
# for the MVP.
class UserActivityHeatmapService
  DEFAULT_DAYS = 365
  # Rolling windows that include today need a short TTL because new activity
  # must surface quickly. Windows that end strictly in the past are immutable
  # (nothing the user does today changes their 2024 totals), so we cache them
  # for a full day to keep year navigation snappy on repeat visits.
  CACHE_TTL_ROLLING = 5.minutes
  CACHE_TTL_HISTORICAL = 24.hours

  def initialize(user, end_date: Date.current, days: DEFAULT_DAYS)
    @user = user
    @end_date = [end_date.to_date, Date.current].min
    @days = days.to_i
    @start_date = @end_date - (@days - 1).days
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: ttl) { build_payload }
  end

  private

  attr_reader :user, :start_date, :end_date, :days

  def ttl
    end_date < Date.current ? CACHE_TTL_HISTORICAL : CACHE_TTL_ROLLING
  end

  def cache_key
    ["user-activity-heatmap-v1", user.id, end_date.iso8601, days].join("-")
  end

  def build_payload
    articles   = articles_by_day
    comments   = comments_by_day
    reactions  = reactions_by_day

    rows = (start_date..end_date).map do |date|
      a = articles[date].to_i
      c = comments[date].to_i
      r = reactions[date].to_i
      { date: date.iso8601, articles: a, comments: c, reactions: r, total: a + c + r }
    end

    totals = {
      articles: articles.values.sum,
      comments: comments.values.sum,
      reactions: reactions.values.sum
    }
    totals[:total] = totals.values.sum

    {
      start_date: start_date.iso8601,
      end_date: end_date.iso8601,
      days: rows,
      totals: totals,
      max: rows.pluck(:total).max || 0
    }
  end

  def articles_by_day
    Article.where(user_id: user.id, published: true)
      .where(published_at: range)
      .group(Arel.sql("DATE(published_at)")).count
      .transform_keys { |k| k.is_a?(String) ? Date.parse(k) : k }
  end

  def comments_by_day
    Comment.where(user_id: user.id, deleted: false)
      .where(created_at: range)
      .group(Arel.sql("DATE(created_at)")).count
      .transform_keys { |k| k.is_a?(String) ? Date.parse(k) : k }
  end

  def reactions_by_day
    Reaction.where(user_id: user.id)
      .public_category.valid_or_confirmed
      .where(created_at: range)
      .group(Arel.sql("DATE(created_at)")).count
      .transform_keys { |k| k.is_a?(String) ? Date.parse(k) : k }
  end

  def range
    start_date.beginning_of_day..end_date.end_of_day
  end
end
