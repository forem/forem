module Articles
  module Feeds
    class Basic
      def initialize(user: nil, number_of_articles: 25, page: 1, tag: nil)
        @user = user
        @number_of_articles = number_of_articles
        @page = page
        @tag = tag
      end

      def feed
        articles = Article.published
          .order(hotness_score: :desc)
          .where(score: 0..)
          .limit(@number_of_articles)
          .limited_column_select.includes(top_comments: :user)
        return articles unless @user

        articles = articles.where.not(user_id: UserBlock.cached_blocked_ids_for_blocker(@user.id))
        articles.sort_by.with_index do |article, index|
          article_tags = article.decorate.cached_tag_list_array
          tag_score = user_followed_tags.sum do |tag|
            article_tags.include?(tag.name) ? tag.points : 0
          end
          user_score = user_following_users_ids.include?(article.user_id) ? 1 : 0
          org_score = user_following_org_ids.include?(article.organization_id) ? 1 : 0
          tag_score + org_score + user_score - index
        end.reverse!
      end

      private

      def user_followed_tags
        @user_followed_tags ||= (@user&.decorate&.cached_followed_tags || [])
      end

      def user_following_org_ids
        @user_following_org_ids ||= (@user&.cached_following_organizations_ids || [])
      end

      def user_following_users_ids
        @user_following_users_ids ||= (@user&.cached_following_users_ids || [])
      end
    end
  end
end
