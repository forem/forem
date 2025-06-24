module Articles
  module Feeds
    TIME_AGO_MAX = Rails.env.production? ? 10.days.ago : 90.days.ago

    class Custom
      def initialize(user: nil, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1, tag: nil, feed_config: nil)
        @user = user
        @number_of_articles = number_of_articles
        @page = [page, 1].max
        @tag = tag
        @feed_config = feed_config
      end

      def default_home_feed(**_kwargs)
        return [] if @feed_config.nil? || @user.nil?
        # Build a raw SQL expression for the computed score.
        # This expression multiplies article fields by weights from feed_config.        
        # **CRITICAL CHANGE:** Use a subquery
        lookback_setting = Settings::UserExperience.feed_lookback_days.to_i
        lookback = lookback_setting.positive? ? lookback_setting.days.ago : TIME_AGO_MAX
        articles = Article.published
          .with_at_least_home_feed_minimum_score
          .select("articles.*, (#{@feed_config.score_sql(@user)}) as computed_score")  # Keep parentheses here
          .from("(#{Article.published.where("articles.published_at > ?", lookback).to_sql}) as articles") # Subquery!
          .order(Arel.sql("computed_score DESC"))
          .limit(@number_of_articles)
          .offset((@page - 1) * @number_of_articles)
          .limited_column_select
          .includes(top_comments: :user)
          .includes(:distinct_reaction_categories)
          .from_subforem

        if @user
          articles = articles.where.not(user_id: UserBlock.cached_blocked_ids_for_blocker(@user.id))
          if (hidden_tags = @user.cached_antifollowed_tag_names).any?
            articles = articles.not_cached_tagged_with_any(hidden_tags)
          end
        end

        articles = weighted_shuffle(articles, @feed_config.shuffle_weight) if @feed_config.shuffle_weight.positive?
        articles
      end

      def weighted_shuffle(arr, shuffle_weight)
        # Each element gets a new sort key: its original index plus a random offset.
        # We choose the random offset uniformly from -2*shuffle_weight to 2*shuffle_weight.
        # The average absolute offset then is (2*shuffle_weight)/2 = shuffle_weight.
        arr.each_with_index.sort_by do |item, index|
          index + (rand * (4 * shuffle_weight) - 2 * shuffle_weight)
        end.map(&:first)
      end
      

      # Preserve the public interface
      alias feed default_home_feed
      alias more_comments_minimal_weight_randomized default_home_feed
    end
  end
end
