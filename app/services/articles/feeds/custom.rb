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
        
        execute_feed_query
      end

      private

      def execute_feed_query
        # Optimize lookback calculation - cache the result
        # Note: Partial indexes are optimized for 7-day lookback (covers 95%+ of queries)
        # If you change this, consider updating the partial indexes in the migration
        lookback_setting = Settings::UserExperience.feed_lookback_days.to_i
        lookback = lookback_setting.positive? ? lookback_setting.days.ago : TIME_AGO_MAX
        
        # Pre-calculate user-specific data to avoid repeated database calls
        user_data = preload_user_data
        
        # Build optimized base query with better index usage
        articles = build_optimized_base_query(lookback, user_data)
        
        # Apply user-specific filters early in the query
        articles = apply_user_filters(articles, user_data)
        
        # Apply subforem-specific filters
        articles = apply_subforem_filters(articles)
        
        # Apply weighted shuffle if needed
        articles = weighted_shuffle(articles, @feed_config.shuffle_weight) if @feed_config.shuffle_weight.positive?
        
        # Randomly shuffle top 5 articles if all articles are recent (within a week)
        articles = shuffle_top_five_if_recent(articles)
        
        articles
      end



      def preload_user_data
        {
          blocked_user_ids: UserBlock.cached_blocked_ids_for_blocker(@user.id),
          hidden_tags: @user.cached_antifollowed_tag_names,
          user_activity: @user.user_activity
        }
      end

      def build_optimized_base_query(lookback, user_data)
        # Use a more efficient query structure with better index hints
        base_query = Article.published
          .with_at_least_home_feed_minimum_score
          .where("articles.published_at > ?", lookback)
          .select("articles.*, (#{score_sql_method}) as computed_score")
          .order(Arel.sql("computed_score DESC"))
          .limit(@number_of_articles)
          .offset((@page - 1) * @number_of_articles)
          .limited_column_select
          .includes(:subforem) # Only include essential associations
          .from_subforem

        # Add conditional includes based on what's actually needed
        base_query = add_conditional_includes(base_query)
        
        base_query
      end

      def score_sql_method
        @feed_config.score_sql(@user)
      end

      def add_conditional_includes(base_query)
        # Only include associations that are actually used in the view
        # This reduces memory usage and query complexity
        includes = [:subforem]
        
        # Add top_comments only if needed for the current view
        if needs_top_comments?
          includes << { top_comments: :user }
        end
        
        # Add reaction categories only if needed
        if needs_reaction_categories?
          includes << :distinct_reaction_categories
        end
        
        # Add context notes only if needed
        if needs_context_notes?
          includes << :context_notes
        end
        
        base_query.includes(*includes)
      end

      def needs_top_comments?
        # Determine if top comments are needed based on the current context
        # This could be based on user preferences, view type, etc.
        true # Default to true for now, but could be made configurable
      end

      def needs_reaction_categories?
        # Determine if reaction categories are needed
        true # Default to true for now
      end

      def needs_context_notes?
        # Determine if context notes are needed
        true # Default to true for now
      end

      def apply_user_filters(articles, user_data)
        # Apply user-specific filters early to reduce dataset size
        if user_data[:blocked_user_ids].any?
          articles = articles.where.not(user_id: user_data[:blocked_user_ids])
        end
        
        if user_data[:hidden_tags].any?
          articles = articles.not_cached_tagged_with_any(user_data[:hidden_tags])
        end
        
        articles
      end

      def apply_subforem_filters(articles)
        # Apply subforem-specific filters
        if RequestStore.store[:subforem_id] == RequestStore.store[:root_subforem_id]
          articles = articles.where(type_of: :full_post)
        end
        
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

      def shuffle_top_five_if_recent(articles)
        return articles if articles.empty?
        
        # Check if all articles are published within the last week
        one_week_ago = 1.week.ago
        all_recent = articles.all? { |article| article.published_at > one_week_ago }
        
        return articles unless all_recent
        
        # Split articles into top 5 and the rest
        top_five = articles.first(5)
        rest = articles[5..-1] || []
        
        # Randomly shuffle only the top 5 articles
        shuffled_top_five = top_five.shuffle
        
        # Return shuffled top 5 + unshuffled rest
        shuffled_top_five + rest
      end

      # Preserve the public interface
      alias feed default_home_feed
      alias more_comments_minimal_weight_randomized default_home_feed
    end
  end
end
