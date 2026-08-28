module Articles
  module Feeds
    # Surfaces posts that are candidates for an engagement boost, i.e.
    # high-quality posts with fewer than the comment threshold. Pass a user as
    # `exclude_author:` to leave that user's own posts out of the feed.
    module EngagementCandidates
      def self.call(exclude_author: nil, page: 1,
                    number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE)
        minimum_score = Settings::UserExperience.home_feed_minimum_score

        scope = Article
          .published
          .where(comments_count: ..5, score: minimum_score..)
        scope = scope.where.not(user_id: exclude_author.id) if exclude_author

        scope
          .order(score: :desc, published_at: :desc)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
