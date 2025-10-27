module Moderations
  class ArticleFetcherService
    SCORE_MIN = -10
    SCORE_MAX = 5
    MINIMUM_ARTICLE_SCORE = -5 # Proxy for filtering out low-quality/spam articles

    def initialize(user:, feed: "inbox", members: "all", tag: nil)
      @user = user
      @feed = feed
      @members = members
      @tag = tag
    end

    def call
      fetch_articles
    end

    private

    attr_reader :user, :feed, :members, :tag

    def fetch_articles
      articles = build_base_query
      articles = apply_tag_filter(articles)
      articles = apply_feed_filter(articles)
      articles = apply_member_filter(articles)
      
      # Filter out [Boost] articles
      articles = articles.reject { |article| article.title == "[Boost]" }
      
      # Convert to JSON with optimized options
      articles.to_json(json_options)
    end

    def build_base_query
      # Use feed lookback setting to limit articles to recent ones only
      lookback_setting = Settings::UserExperience.feed_lookback_days.to_i
      lookback = lookback_setting.positive? ? lookback_setting.days.ago : 10.days.ago
      
      Article.published
        .from_subforem
        .includes(:user) # Eager load to avoid N+1
        .where("articles.score >= ?", MINIMUM_ARTICLE_SCORE)
        .where("articles.published_at > ?", lookback) # Only recent articles
        .order(published_at: :desc)
        .limit(50)
    end

    def apply_tag_filter(articles)
      return articles unless tag.present?
      
      articles.cached_tagged_with(tag)
    end

    def apply_feed_filter(articles)
      return articles unless feed == "inbox"

      articles
        .where("articles.score >= ? AND articles.score <= ?", SCORE_MIN, SCORE_MAX)
        .where("NOT EXISTS (
          SELECT 1 FROM reactions 
          WHERE reactions.reactable_id = articles.id 
          AND reactions.reactable_type = 'Article' 
          AND reactions.user_id = ?
        )", user.id)
    end

    def apply_member_filter(articles)
      case members
      when "new"
        articles.where("nth_published_by_author > 0 AND nth_published_by_author < 4")
      when "not_new"
        articles.where("nth_published_by_author > 3")
      else
        articles
      end
    end

    def json_options
      {
        only: %i[id title published_at cached_tag_list path nth_published_by_author],
        include: {
          user: { only: %i[username name path articles_count id] }
        }
      }
    end
  end
end
