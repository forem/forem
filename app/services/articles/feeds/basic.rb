module Articles
  module Feeds
    class Basic
      def initialize(user: nil, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1, tag: nil)
        @user = user
        @number_of_articles = number_of_articles
        @page = page
        @tag = tag
        @article_score_applicator = Articles::Feeds::ArticleScoreCalculatorForUser.new(user: @user)
      end

      def default_home_feed(**_kwargs)
        articles = Article.published
          .order(hotness_score: :desc)
          .with_at_least_home_feed_minimum_score
          .limit(@number_of_articles)
          .limited_column_select.includes(top_comments: :user)
        return articles unless @user

        articles = articles.where.not(user_id: UserBlock.cached_blocked_ids_for_blocker(@user.id))
        articles.sort_by.with_index do |article, index|
          tag_score = score_followed_tags(article)
          user_score = score_followed_user(article)
          org_score = score_followed_organization(article)

          # NOTE: Not quite understanding the purpose of the `-
          # index`.  My guess is that it helps reduce the impact of the
          # hotness score on the sort order.
          tag_score + org_score + user_score - index
        end.reverse!
      end

      # Alias :feed to preserve past implementations, but favoring a
      # convergence of interface implementations.
      alias feed default_home_feed

      # Creating :more_comments_minimal_weight_randomized to conform
      # to the public interface of
      # Articles::Feeds::LargeForemExperimental
      alias more_comments_minimal_weight_randomized default_home_feed

      delegate(:score_followed_tags,
               :score_followed_user,
               :score_followed_organization,
               to: :@article_score_applicator)
    end
  end
end
