module Articles
  module Feeds
    class LargeForemExperimental
      def initialize(user: nil, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1, tag: nil)
        @user = user
        @number_of_articles = number_of_articles
        @page = page
        @tag = tag
        @article_score_applicator = Articles::Feeds::ArticleScoreCalculatorForUser.new(user: user)
      end

      def default_home_feed(user_signed_in: false)
        _featured_story, stories = featured_story_and_default_home_feed(user_signed_in: user_signed_in, ranking: true)
        stories
      end

      # @param user_signed_in [Boolean] are we treating this as an
      #        anonymous user?
      # @param ranking [Boolean] if true, apply a ranking algorithm
      # @param must_have_main_image [Boolean] if true, the featured
      #        story must have a main image
      #
      # @note the must_have_main_image parameter name matches PR #15240
      def featured_story_and_default_home_feed(user_signed_in: false, ranking: true, must_have_main_image: true)
        featured_story, hot_stories = globally_hot_articles(user_signed_in, must_have_main_image: must_have_main_image)
        hot_stories = rank_and_sort_articles(hot_stories) if @user && ranking
        [featured_story, hot_stories]
      end

      # Adding an alias to preserve public method signature.
      # Eventually, we should be able to remove the alias.
      alias default_home_feed_and_featured_story featured_story_and_default_home_feed

      def more_comments_minimal_weight_randomized
        _featured_story, stories = featured_story_and_default_home_feed(user_signed_in: true)
        first_quarter(stories).shuffle + last_three_quarters(stories)
      end

      # Adding an alias to preserve public method signature.  However,
      # in this code base there are no further references of
      # :more_comments_minimal_weight_randomized_at_end
      alias more_comments_minimal_weight_randomized_at_end more_comments_minimal_weight_randomized

      # @api private
      def rank_and_sort_articles(articles)
        ranked_articles = articles.each_with_object({}) do |article, result|
          article_points = score_single_article(article)
          result[article] = article_points
        end
        ranked_articles = ranked_articles.sort_by { |_article, article_points| -article_points }.map(&:first)
        ranked_articles.to(@number_of_articles - 1)
      end

      # @api private
      def score_single_article(article, base_article_points: 0)
        article_points = base_article_points
        article_points += score_followed_user(article)
        article_points += score_followed_organization(article)
        article_points += score_followed_tags(article)
        article_points += score_experience_level(article)
        article_points += score_comments(article)
        article_points
      end

      delegate(:score_followed_user,
               :score_followed_tags,
               :score_followed_organization,
               :score_experience_level,
               :score_comments,
               to: :@article_score_applicator)

      # @api private
      # rubocop:disable Layout/LineLength
      def globally_hot_articles(user_signed_in, must_have_main_image: true, article_score_threshold: -15, min_rand_limit: 15, max_rand_limit: 80)
        # rubocop:enable Layout/LineLength
        if user_signed_in
          hot_stories = experimental_hot_story_grab
          hot_stories = hot_stories.not_authored_by(UserBlock.cached_blocked_ids_for_blocker(@user.id))
          featured_story = featured_story_from(stories: hot_stories, must_have_main_image: must_have_main_image)
          new_stories = Article.published.from_subforem
            .where("score > ?", article_score_threshold)
            .limited_column_select.includes(top_comments: :user)
            .order(published_at: :desc)
            .includes(:distinct_reaction_categories)
            .limit(rand(min_rand_limit..max_rand_limit))
          hot_stories = hot_stories.to_a + new_stories.to_a
        else
          hot_stories = Article.published.from_subforem.limited_column_select
            .includes(:distinct_reaction_categories)
            .page(@page).per(@number_of_articles)
            .with_at_least_home_feed_minimum_score
            .order(hotness_score: :desc)
          featured_story = featured_story_from(stories: hot_stories, must_have_main_image: must_have_main_image)
        end
        [featured_story, hot_stories.to_a]
      end

      private

      def featured_story_from(stories:, must_have_main_image:)
        return stories.first unless must_have_main_image

        stories.where.not(main_image: nil).first
      end

      def experimental_hot_story_grab
        start_time = Articles::Feeds.oldest_published_at_to_consider_for(user: @user)
        Article.published.limited_column_select.includes(top_comments: :user)
          .includes(:distinct_reaction_categories)
          .where("published_at > ?", start_time)
          .page(@page).per(@number_of_articles)
          .order(score: :desc)
      end

      def first_quarter(array)
        array[0...(array.length / 4)]
      end

      def last_three_quarters(array)
        array[(array.length / 4)..array.length]
      end
    end
  end
end
