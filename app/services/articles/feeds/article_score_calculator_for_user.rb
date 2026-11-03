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
        not_followed_org_score: 0,
        some_ai_penalty: -10,
        fully_autonomous_penalty: -25
      }.freeze

      # @param user [User] the user for whom we're calculating the article score.
      # @param config [Hash<Symbol,(Integer|Float)>] exposes the means
      #   for overriding the default configuration values
      #
      # @see DEFAULT_CONFIGURATION
      def initialize(user:, config: {})
        @user = user
        DEFAULT_CONFIGURATION.each_pair do |key, value|
          instance_variable_set(:"@#{key}", config.fetch(key, value))
        end
      end

      # @api private
      def score_followed_user(article)
        user_following_users_ids.include?(article.user_id) ? @followed_user_score : @not_followed_user_score
      end

      # @api private
      def score_followed_tags(article)
        return @nil_user_tag_score unless @user

        if article.respond_to?(:cached_tag_list)
          score = ForemNative.score_followed_tags(
            article.cached_tag_list, user_followed_tag_names, user_followed_tag_points,
            @followed_tag_weight, @not_followed_tag_score
          )
          return score if score
        end

        legacy_score_followed_tags(article)
      end

      # @api private
      def score_followed_organization(article)
        return @not_followed_org_score unless article.organization_id?

        user_following_org_ids.include?(article.organization_id) ? @followed_org_score : @not_followed_org_score
      end

      # @api private
      def score_experience_level(article)
        user_experience_level = @user&.setting&.experience_level || @default_user_xp_level

        ForemNative.score_experience_level(
          article.experience_level_rating, user_experience_level, @xp_level_weight
        ) || legacy_score_experience_level(article, user_experience_level)
      end

      # @api private
      def score_comments(article)
        article.comments_count * @comment_weight
      end

      # @api private
      def score_ai_disclosure(article)
        return 0 unless @user&.setting

        ForemNative.score_ai_disclosure(
          @user.setting.feed_ai_preference, article.ai_disclosure_level,
          @some_ai_penalty, @fully_autonomous_penalty
        ) || legacy_score_ai_disclosure(article)
      end

      # @api private
      def score_for_experimental(article, base_article_points: 0)
        return unless native_experimental_article?(article)

        ForemNative.score_article_for_user(
          native_user_context,
          article.user_id,
          article.organization_id? ? article.organization_id : nil,
          article.cached_tag_list,
          article.experience_level_rating,
          article.comments_count,
          article.ai_disclosure_level,
          base_article_points,
        )
      end

      # @api private
      def rank_for_basic_feed(articles)
        article_list = articles.to_a
        tuples = native_basic_article_tuples(article_list)
        ForemNative.rank_articles_for_basic_feed(article_list, native_user_context, tuples) if tuples
      end

      private

      def legacy_score_followed_tags(article)
        article_tags = article.decorate.cached_tag_list_array
        user_followed_tags.sum do |tag|
          article_tags.include?(tag.name) ? tag.points * @followed_tag_weight : @not_followed_tag_score
        end
      end

      def legacy_score_experience_level(article, user_experience_level)
        - (((article.experience_level_rating - user_experience_level).abs / 2) * @xp_level_weight)
      end

      def legacy_score_ai_disclosure(article)
        case @user.setting.feed_ai_preference
        when "minimize_ai"
          case article.ai_disclosure_level
          when "some_ai" then @some_ai_penalty
          when "fully_autonomous" then @fully_autonomous_penalty
          else 0
          end
        when "hide_fully_autonomous"
          article.ai_disclosure_level == "some_ai" ? @some_ai_penalty : 0
        else 0
        end
      end

      def native_user_context
        return @native_user_context if @native_user_context && @cached_comment_weight == @comment_weight

        @cached_comment_weight = @comment_weight
        @native_user_context = [
          !@user.nil?, user_following_users_ids, user_following_org_ids,
          user_followed_tag_names, user_followed_tag_points,
          @user&.setting&.experience_level || @default_user_xp_level,
          @user&.setting&.feed_ai_preference,
          @comment_weight, @xp_level_weight, @followed_user_score, @not_followed_user_score,
          @nil_user_tag_score, @followed_tag_weight, @not_followed_tag_score,
          @followed_org_score, @not_followed_org_score, @some_ai_penalty, @fully_autonomous_penalty
        ].freeze
      end

      def native_basic_article?(article)
        %i[cached_tag_list user_id organization_id? organization_id ai_disclosure_level].all? do |m|
          article.respond_to?(m)
        end
      end

      def native_experimental_article?(article)
        native_basic_article?(article) &&
          article.respond_to?(:experience_level_rating) &&
          article.respond_to?(:comments_count)
      end

      def native_basic_article_tuples(article_list)
        article_list.map do |a|
          return nil unless native_basic_article?(a)

          [a.user_id, a.organization_id? ? a.organization_id : nil, a.cached_tag_list, 5, 0, a.ai_disclosure_level]
        end
      end

      def user_followed_tags = @user_followed_tags ||= @user&.decorate&.cached_followed_tags || []
      def user_followed_tag_names = @user_followed_tag_names ||= user_followed_tags.map(&:name)
      def user_followed_tag_points = @user_followed_tag_points ||= user_followed_tags.map(&:points)
      def user_following_org_ids = @user_following_org_ids ||= @user&.cached_following_organizations_ids || []
      def user_following_users_ids = @user_following_users_ids ||= @user&.cached_following_users_ids || []
    end
  end
end
