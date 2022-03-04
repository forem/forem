module Articles
  module Feeds
    # @api private
    #
    # The purpose of this class is to encapsulate how we apply scores
    # to an article.
    #
    # @see Articles::Feeds::Basic
    # @see Articles::Feeds::LargeForemExperimental
    class ArticleScoreCalculatorForUser
      # This constant defines some of the levers that we use to help
      # calculate an article's score.
      DEFAULT_CONFIGURATION = {
        comment_weight: 0.2,
        xp_level_weight: 1,
        default_user_xp_level: 5,
        followed_user_score: 1,
        not_followed_user_score: 0,
        nil_user_tag_score: 0,
        followed_tag_weight: 1,
        not_followed_tag_score: 0,
        followed_org_score: 1,
        not_followed_org_score: 0
      }.freeze

      # @param user [User] the user for whom we're calculating the article score.
      # @param config [Hash<Symbol,(Integer|Float)>] exposes the means
      #   for overriding the default configuration values
      #
      # @see DEFAULT_CONFIGURATION
      def initialize(user:, config: {})
        @user = user
        DEFAULT_CONFIGURATION.each_pair do |key, value|
          instance_variable_set("@#{key}", config.fetch(key, value))
        end
      end

      # @api private
      def score_followed_user(article)
        user_following_users_ids.include?(article.user_id) ? @followed_user_score : @not_followed_user_score
      end

      # @api private
      def score_followed_tags(article)
        return @nil_user_tag_score unless @user

        article_tags = article.decorate.cached_tag_list_array
        user_followed_tags.sum do |tag|
          article_tags.include?(tag.name) ? tag.points * @followed_tag_weight : @not_followed_tag_score
        end
      end

      # @api private
      def score_followed_organization(article)
        return @not_followed_org_score unless article.organization_id?

        user_following_org_ids.include?(article.organization_id) ? @followed_org_score : @not_followed_org_score
      end

      # @api private
      def score_experience_level(article)
        user_experience_level = @user&.setting&.experience_level || @default_user_xp_level

        # Calculate the distance between the user's experience level
        # and that of the article's experience level.
        - (((article.experience_level_rating - user_experience_level).abs / 2) * @xp_level_weight)
      end

      # @api private
      def score_comments(article)
        article.comments_count * @comment_weight
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
