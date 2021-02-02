module Articles
  module Feeds
    class LargeForemExperimental
      include FieldTest::Helpers
      MINIMUM_SCORE_LATEST_FEED = -20

      def initialize(user: nil, number_of_articles: 50, page: 1, tag: nil)
        @user = user
        @number_of_articles = number_of_articles
        @page = page
        @tag = tag
        @randomness = 3 # default number for randomly adjusting feed
        @tag_weight = 1 # default weight tags play in rankings
        @comment_weight = 0 # default weight comments play in rankings
        @experience_level_weight = 1 # default weight for user experience level
      end

      def self.find_featured_story(stories)
        featured_story =  if stories.is_a?(ActiveRecord::Relation)
                            stories.where.not(main_image: nil).first
                          else
                            stories.detect { |story| story.main_image.present? }
                          end
        featured_story || Article.new
      end

      def find_featured_story(stories)
        self.class.find_featured_story(stories)
      end

      def published_articles_by_tag
        articles = Article.published.limited_column_select
          .includes(top_comments: :user)
          .page(@page).per(@number_of_articles)
        articles = articles.cached_tagged_with(@tag) if @tag.present? # More efficient than tagged_with
        articles
      end

      # Timeframe values from Timeframe::DATETIMES
      def top_articles_by_timeframe(timeframe:)
        published_articles_by_tag.where("published_at > ?", Timeframe.datetime(timeframe))
          .order(score: :desc).page(@page).per(@number_of_articles)
      end

      def default_home_feed(user_signed_in: false)
        _featured_story, stories = default_home_feed_and_featured_story(user_signed_in: user_signed_in, ranking: true)
        stories
      end

      def latest_feed
        published_articles_by_tag.order(published_at: :desc)
          .where("score > ?", MINIMUM_SCORE_LATEST_FEED)
          .page(@page).per(@number_of_articles)
      end

      def default_home_feed_and_featured_story(user_signed_in: false, ranking: true)
        featured_story, hot_stories = globally_hot_articles(user_signed_in)
        hot_stories = rank_and_sort_articles(hot_stories) if @user && ranking
        [featured_story, hot_stories]
      end

      def more_comments_minimal_weight
        @comment_weight = 0.2
        _featured_story, stories = default_home_feed_and_featured_story(user_signed_in: true)
        stories
      end

      def more_comments_minimal_weight_randomized_at_end
        @randomness = 0
        results = more_comments_minimal_weight
        first_half(results).shuffle + last_half(results)
      end

      def rank_and_sort_articles(articles)
        ranked_articles = articles.each_with_object({}) do |article, result|
          article_points = score_single_article(article)
          result[article] = article_points
        end
        ranked_articles = ranked_articles.sort_by { |_article, article_points| -article_points }.map(&:first)
        ranked_articles.to(@number_of_articles - 1)
      end

      def score_single_article(article)
        article_points = 0
        article_points += score_followed_user(article)
        article_points += score_followed_organization(article)
        article_points += score_followed_tags(article)
        article_points += score_randomness
        article_points += score_language(article)
        article_points += score_experience_level(article)
        article_points += score_comments(article)
        article_points
      end

      def score_followed_user(article)
        user_following_users_ids.include?(article.user_id) ? 1 : 0
      end

      def score_followed_tags(article)
        return 0 unless @user

        article_tags = article.decorate.cached_tag_list_array
        user_followed_tags.sum do |tag|
          article_tags.include?(tag.name) ? tag.points * @tag_weight : 0
        end
      end

      def score_followed_organization(article)
        user_following_org_ids.include?(article.organization_id) ? 1 : 0
      end

      def score_randomness
        rand(3) * @randomness
      end

      def score_language(article)
        @user&.preferred_languages_array&.include?(article.language || "en") ? 1 : -15
      end

      def score_experience_level(article)
        - (((article.experience_level_rating - (@user&.experience_level || 5)).abs / 2) * @experience_level_weight)
      end

      def score_comments(article)
        article.comments_count * @comment_weight
      end

      def globally_hot_articles(user_signed_in)
        if user_signed_in
          hot_stories = experimental_hot_story_grab
          hot_stories = hot_stories.where.not(user_id: UserBlock.cached_blocked_ids_for_blocker(@user.id))
          featured_story = hot_stories.where.not(main_image: nil).first
          new_stories = Article.published
            .where("score > ?", -15)
            .limited_column_select.includes(top_comments: :user).order(published_at: :desc).limit(rand(15..80))
          hot_stories = hot_stories.to_a + new_stories.to_a
        else
          hot_stories = Article.published.limited_column_select
            .page(@page).per(@number_of_articles)
            .where("score >= ? OR featured = ?", SiteConfig.home_feed_minimum_score, true)
            .order(hotness_score: :desc)
          featured_story = hot_stories.where.not(main_image: nil).first
        end
        [featured_story, hot_stories.to_a]
      end

      private

      # Disable complexity cop to allow for variant-driven method
      # rubocop:disable Metrics/CyclomaticComplexity
      def experimental_hot_story_grab
        test_variant = @user ? field_test(:feed_top_articles_query, participant: @user) : "base"
        case test_variant
        when "base_with_more_articles" # equivalent to current base but with higher "number of articles"
          articles = Article.published.limited_column_select.includes(top_comments: :user)
            .page(@page).per(75)
            .where("score >= ? OR featured = ?", SiteConfig.home_feed_minimum_score, true)
            .order(hotness_score: :desc)
        when "only_followed_tags" # equivalent to base but only on tags user follows (if user follows enough)
          followed_tags = @user.cached_followed_tag_names
          articles = Article.published.includes(top_comments: :user)
            .page(@page).per(@number_of_articles)
            .where("score >= ? OR featured = ?", SiteConfig.home_feed_minimum_score, true)
            .order(hotness_score: :desc)
          # We only want to limit the posts to tagged_with if the participant follows enough tags.
          articles = articles.tagged_with(followed_tags, any: true) if followed_tags.size > 4

          articles = articles.unscope(:select).limited_column_select
        when "top_articles_since_last_pageview_3_days_max" # Top articles since last page view (max 3 days)
          start_time = [(@user.page_views.last&.created_at || 3.days.ago) - 12.hours, 3.days.ago].max
          articles = Article.published.limited_column_select.includes(top_comments: :user)
            .where("published_at > ?", start_time)
            .page(@page).per(@number_of_articles)
            .order(score: :desc)
        when "top_articles_since_last_pageview_7_days_max" # Top articles since last page view (max 7 days)
          start_time = [(@user.page_views.last&.created_at || 7.days.ago) - 12.hours, 7.days.ago].max
          articles = Article.published.limited_column_select.includes(top_comments: :user)
            .where("published_at > ?", start_time)
            .page(@page).per(@number_of_articles)
            .order(score: :desc)
        when "combination_only_tags_followed_and_top_max_7_days" # Top articles since last page view (max 7 days)
          start_time = [(@user.page_views.last&.created_at || 7.days.ago) - 12.hours, 7.days.ago].max
          followed_tags = @user.cached_followed_tag_names
          articles = Article.published.includes(top_comments: :user)
            .where("published_at > ?", start_time)
            .page(@page).per(@number_of_articles)
            .order(score: :desc)
          # We only want to limit the posts to tagged_with if the participant follows enough tags.
          articles = articles.tagged_with(followed_tags, any: true) if followed_tags.size > 4

          articles = articles.unscope(:select).limited_column_select
        else # "base"
          articles = Article.published.limited_column_select.includes(top_comments: :user)
            .page(@page).per(@number_of_articles)
            .where("score >= ? OR featured = ?", SiteConfig.home_feed_minimum_score, true)
            .order(hotness_score: :desc)
        end
        articles
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def user_followed_tags
        @user_followed_tags ||= (@user&.decorate&.cached_followed_tags || [])
      end

      def user_following_org_ids
        @user_following_org_ids ||= (@user&.cached_following_organizations_ids || [])
      end

      def user_following_users_ids
        @user_following_users_ids ||= (@user&.cached_following_users_ids || [])
      end

      def first_half(array)
        array[0...(array.length / 2)]
      end

      def last_half(array)
        array[(array.length / 2)..array.length]
      end
    end
  end
end
