module Stories
  class FeedsController < ApplicationController
    include Instrumentation

    respond_to :json

    before_action :current_user_by_token, only: [:show]

    def show
      @page = (params[:page] || 1).to_i
      # This most recent test has concluded with a winner. Preserved as a comment awaiting next test
      # @comments_variant = field_test(:comments_to_display_20240129, participant: @user)
      @comments_variant = "more_inclusive_recent_good_comments"

      # Preload frequently accessed settings to avoid N+1 queries
      preload_common_settings

      @stories = assign_feed_stories

      # After getting stories, preload settings for any additional subforems if in root
      preload_additional_subforem_settings

      add_pinned_article
      preload_feed_associations

      # Add edge cache headers for signed out users only
      return if user_signed_in?

      set_cache_control_headers(60) # 1 minute expiration
    end

    private

    def add_pinned_article
      return if params[:timeframe].present?

      pinned_article = PinnedArticle.get
      return if pinned_article.nil? || @stories.detect { |story| story.id == pinned_article.id }

      @stories.prepend(pinned_article.decorate)
    end

    def assign_feed_stories
      params[:type_of] = "discover" unless params[:type_of].in?(%w[discover following curated])

      stories = if params[:timeframe].in?(Timeframe::FILTER_TIMEFRAMES)
                  timeframe_feed
                elsif params[:type_of] == "following" && user_signed_in? && params[:timeframe].in?([Timeframe::LATEST_TIMEFRAME, "latest_less_filtered"])
                  latest_following_feed
                elsif params[:type_of] == "following" && user_signed_in?
                  relevant_following_feed
                elsif params[:type_of] == "curated"
                  curated_feed
                elsif params[:timeframe] == "latest_less_filtered"
                  latest_less_filtered_feed
                elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
                  latest_feed
                elsif user_signed_in?
                  signed_in_base_feed
                else
                  signed_out_base_feed
                end

      ArticleDecorator.decorate_collection(stories)
    end

    def signed_in_base_feed
      feed_strategy = params[:mode] || Settings::UserExperience.feed_strategy
      feed = if feed_strategy == "basic" && params[:type_of] != "following"
               Articles::Feeds::Basic.new(user: current_user, page: @page, tag: params[:tag])
             elsif feed_strategy == "configured" && params[:type_of] != "following"
               @feed_config = FeedConfig.select_for_feed(
                 preferred_id: params[:item],
                 user: current_user,
                 context_type: FeedEvent::CONTEXT_TYPE_HOME,
               )
               Articles::Feeds::Custom.new(user: current_user, page: @page, tag: params[:tag],
                                           feed_config: @feed_config)
             else
               Articles::Feeds.feed_for(
                 user: current_user,
                 controller: self,
                 page: @page,
                 tag: params[:tag],
                 number_of_articles: 35,
                 type_of: params[:type_of] || "discover",
               )
             end
      # Hey, why the to_a you say?  Because the
      # LargeForemExperimental has already done this.  But the
      # weighted strategy has not.  I also don't want to alter the
      # weighted query implementation as it returns a lovely
      # ActiveRecord::Relation.  So this is a compromise.

      instrument("feed.query",
                 span_type: "db",
                 resource: "#{self.class}.#{__method__}",
                 tags: { feed_class: feed.class.to_s.dasherize }) do
        feed.more_comments_minimal_weight_randomized(comments_variant: @comments_variant)
      end
    end

    def signed_out_base_feed
      feed = if Settings::UserExperience.feed_strategy == "basic"
               Articles::Feeds::Basic.new(user: nil, page: @page, tag: params[:tag])
             else
               Articles::Feeds.feed_for(
                 user: current_user,
                 controller: self,
                 page: @page,
                 tag: params[:tag],
                 number_of_articles: 25,
                 type_of: "discover",
               )
             end
      instrument("feed.query",
                 span_type: "db",
                 resource: "#{self.class}.#{__method__}",
                 tags: { feed_class: feed.class.to_s.dasherize }) do
        # Hey, why the to_a you say?  Because the
        # LargeForemExperimental has already done this.  But the
        # weighted strategy has not.  I also don't want to alter the
        # weighted query implementation as it returns a lovely
        # ActiveRecord::Relation.  So this is a compromise.
        feed.default_home_feed(user_signed_in: false).to_a
      end
    end

    def timeframe_feed
      Articles::Feeds::Timeframe.call(params[:timeframe], tag: params[:tag], page: @page)
    end

    def latest_feed
      articles = Articles::Feeds::Latest.call(tag: params[:tag], page: @page)
      minimum_score = Settings::UserExperience.index_minimum_score
      
      if user_signed_in?
        articles.where("score >= ? OR user_id = ?", minimum_score, current_user.id)
      else
        articles.where("score >= ?", minimum_score)
      end
    end

    def latest_less_filtered_feed
      Articles::Feeds::Latest.call(tag: params[:tag], page: @page)
    end

    def curated_feed
      Articles::Feeds::Curated.call(
        user: current_user,
        tag: params[:tag],
        page: @page,
        number_of_articles: 25,
      )
    end

    def latest_following_feed
      activity = current_user.user_activity
      user_ids = activity&.alltime_users || current_user.cached_following_users_ids
      organization_ids = activity&.alltime_organizations || current_user.cached_following_organizations_ids
      left_scope  = Article.published.from_subforem.where(user_id: user_ids)
      right_scope = Article.published.from_subforem.where(organization_id: organization_ids)

      @articles = left_scope
        .or(right_scope)
        .limited_column_select
        .where("score > -10")
        .order("published_at DESC")
        .page(@page)
        .per(25)
    end

    def relevant_following_feed
      activity = current_user.user_activity
      user_ids = activity&.alltime_users || current_user.cached_following_users_ids
      organization_ids = activity&.alltime_organizations || current_user.cached_following_organizations_ids
      left_scope  = Article.published.from_subforem.where(user_id: user_ids)
      right_scope = Article.published.from_subforem.where(organization_id: organization_ids)

      @articles = left_scope
        .or(right_scope)
        .limited_column_select
        .where("score > -10")
        .order("hotness_score DESC")
        .page(@page)
        .per(25)
    end

    def preload_feed_associations
      records = @stories.map(&:object)
      if @page <= 2 && perform_caching && records.any?
        vc = view_context
        digest_path = vc.digest_path_from_template(lookup_context.find("stories/feeds/show", [], false, [], formats: [:json]))
        @story_cache_keys = {}
        keys = records.index_by { |r| @story_cache_keys[r.id] = story_cache_key(r, vc, digest_path) }
        @cached_story_fragments = Rails.cache.read_multi(*keys.keys)
        records = keys.except(*@cached_story_fragments.keys).values
      end
      return if records.empty?

      notes_missing = records.reject { |r| r.association(:context_notes).loaded? }
      if notes_missing.any?
        ActiveRecord::Associations::Preloader.new(
          records: notes_missing, associations: :context_notes, scope: ContextNote.order(:id),
        ).call
      end

      comments_assoc = @comments_variant.to_sym
      comments_missing = records.select { |r| r.comments_count.positive? && !r.association(comments_assoc).loaded? }
      if comments_missing.any?
        ranked = Comment.where(
          commentable_type: "Article", commentable_id: comments_missing.map(&:id),
          score: 5.., ancestry: nil, hidden_by_commentable_user: false, deleted: false
        ).select("comments.id, ROW_NUMBER() OVER (PARTITION BY commentable_id ORDER BY created_at DESC) AS rn")
        ActiveRecord::Associations::Preloader.new(
          records: comments_missing, associations: comments_assoc,
          scope: Comment.where(id: Comment.from(ranked, :ranked_comments).where("rn <= 3").select(:id)).includes(:user)
        ).call
      end

      Article.preload_reaction_counts_for_reactable(records.select { |r| r.public_reactions_count.positive? })
    end

    def story_cache_key(rec, vc, digest_path)
      raw_key = ["article", rec.id, rec.updated_at, rec.edited_at, rec.last_comment_at, rec.public_reactions_count,
                 rec.favorited_by_user_id, rec.cached_user, rec.cached_organization, I18n.locale].join("-")
      ActiveSupport::Cache.expand_cache_key(
        combined_fragment_cache_key(vc.cache_fragment_name(raw_key, digest_path: digest_path)), :jbuilder
      )
    end

    def preload_common_settings
      # Preload frequently accessed settings to avoid N+1 queries from waterfall analysis
      # This addresses the multiple site_configs queries we see in the performance trace
      current_subforem_id = RequestStore.store[:subforem_id]
      root_subforem_id = RequestStore.store[:root_subforem_id]

      if current_subforem_id == root_subforem_id
        # We're in root subforem - need to handle multiple subforems dynamically
        # We'll cache settings for the most common subforems to avoid repeated queries
        @cached_subforem_logos = {}
        @cached_logo_png = Settings::General.logo_png(subforem_id: current_subforem_id)
      else
        # Single subforem - simple caching
        @cached_logo_png = Settings::General.logo_png(subforem_id: current_subforem_id)
        @cached_subforem_logo = @cached_logo_png
      end
    end

    def preload_additional_subforem_settings
      # Only needed when we're in root subforem and have multiple subforems in the feed
      return unless @cached_subforem_logos && @stories.any?

      # Get unique subforem IDs from the stories
      unique_subforem_ids = @stories.map(&:subforem_id).uniq.compact
      current_subforem_id = RequestStore.store[:subforem_id]

      # Preload settings for all unique subforems (excluding current one which is already cached)
      unique_subforem_ids.each do |subforem_id|
        next if subforem_id == current_subforem_id

        @cached_subforem_logos[subforem_id] ||= Settings::General.logo_png(subforem_id: subforem_id)
      end
    end
  end
end
