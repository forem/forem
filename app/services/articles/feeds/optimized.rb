module Articles
  module Feeds
    class Optimized < Basic
      def initialize(user: nil, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1, tag: nil)
        super
        @optimization_context = determine_optimization_context
      end

      def default_home_feed(**_kwargs)
        articles = Article.published
          .order(hotness_score: :desc)
          .with_at_least_home_feed_minimum_score
          .limit(@number_of_articles)
          .offset((@page - 1) * @number_of_articles)
          .limited_column_select
          .from_subforem

        # Apply conditional includes based on optimization context
        articles = apply_conditional_includes(articles)

        return articles unless @user

        articles = articles.where.not(user_id: UserBlock.cached_blocked_ids_for_blocker(@user.id))
        if (hidden_tags = @user.cached_antifollowed_tag_names).any?
          articles = articles.not_cached_tagged_with_any(hidden_tags)
        end
        articles.sort_by.with_index do |article, index|
          tag_score = score_followed_tags(article)
          user_score = score_followed_user(article)
          org_score = score_followed_organization(article)

          tag_score + org_score + user_score - index
        end.reverse!
      end

      private

      def determine_optimization_context
        # Determine what optimizations to apply based on the request context
        {
          load_comments: should_load_comments?,
          load_reaction_categories: should_load_reaction_categories?,
          load_context_notes: should_load_context_notes?,
          load_body_preview: should_load_body_preview?
        }
      end

      def apply_conditional_includes(articles)
        includes = []

        # Always include reaction categories as they're commonly used
        includes << :distinct_reaction_categories if @optimization_context[:load_reaction_categories]

        # Only include comments if we expect them to be needed
        if @optimization_context[:load_comments]
          includes << { top_comments: :user }
        end

        # Only include context notes if they're likely to be used
        if @optimization_context[:load_context_notes]
          includes << :context_notes
        end

        articles.includes(*includes) if includes.any?
        articles
      end

      def should_load_comments?
        # Load comments if we're in a context where they're likely to be displayed
        # This could be based on user preferences, feed type, etc.
        true # For now, keep existing behavior but make it conditional
      end

      def should_load_reaction_categories?
        # Reaction categories are commonly used for display
        true
      end

      def should_load_context_notes?
        # Context notes are rarely used, make this more selective
        false # Optimize by default, can be enabled per request if needed
      end

      def should_load_body_preview?
        # Body preview is only needed for status articles
        # This is handled in the view layer, not the query layer
        false
      end
    end
  end
end
