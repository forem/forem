module Favorites
  # Ranks users by the downstream engagement of their favorite content. Results
  # are cached internally.
  #
  # Impact is the engagement accrued on favorited content:
  #   - articles: comments_count + public_reactions_count + page_views_count
  #   - comments: public_reactions_count
  #
  # Impact calculation and caching are provisional and should be tuned to fit.
  class ImpactData
    CACHE_KEY = "favorites_impact_data".freeze

    ARTICLE_IMPACT_SQL = "COALESCE(SUM(comments_count + public_reactions_count + page_views_count), 0)".freeze
    COMMENT_IMPACT_SQL = "COALESCE(SUM(public_reactions_count), 0)".freeze

    LIMIT = 25
    PERIOD = 3.months

    Row = Struct.new(
      :user, :article_favorites_count, :comment_favorites_count,
      :favorites_count, :impact_score,
      keyword_init: true
    )

    def self.call(...)
      new(...).call
    end

    def initialize(limit: LIMIT)
      @limit = limit
    end

    def call
      aggregates = Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) do
        ranked_aggregates
      end

      hydrate(aggregates.first(limit))
    end

    private

    attr_reader :limit

    # Cache-safe aggregated per-user data ranked by impact. Returns an array of
    # { user_id:, articles:, comments:, impact: }.
    def ranked_aggregates
      totals = Hash.new { |hash, key| hash[key] = { articles: 0, comments: 0, impact: 0 } }
      range = (PERIOD.ago..)

      Article.favorited.where(published_at: range).group(:favorited_by_user_id)
        .pluck(:favorited_by_user_id, Arel.sql("COUNT(*)"), Arel.sql(ARTICLE_IMPACT_SQL))
        .each do |user_id, count, impact|
          totals[user_id][:articles] = count
          totals[user_id][:impact] += impact.to_i
        end

      Comment.favorited.where(created_at: range).group(:favorited_by_user_id)
        .pluck(:favorited_by_user_id, Arel.sql("COUNT(*)"), Arel.sql(COMMENT_IMPACT_SQL))
        .each do |user_id, count, impact|
          totals[user_id][:comments] = count
          totals[user_id][:impact] += impact.to_i
        end

      totals
        .map { |user_id, row| row.merge(user_id: user_id) }
        .sort_by { |row| -row[:impact] }
    end

    # Turns aggregate data into Rows with live Users, preserving ranked order.
    def hydrate(aggregates)
      users = User.where(id: aggregates.pluck(:user_id)).index_by(&:id)

      aggregates.filter_map do |row|
        user = users[row[:user_id]]
        next unless user

        Row.new(
          user: user,
          article_favorites_count: row[:articles],
          comment_favorites_count: row[:comments],
          favorites_count: row[:articles] + row[:comments],
          impact_score: row[:impact],
        )
      end
    end
  end
end
