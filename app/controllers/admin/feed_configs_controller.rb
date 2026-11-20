module Admin
  class FeedConfigsController < Admin::ApplicationController
    layout "admin"

    PER_PAGE = 25
    VALID_STATUS_MODES = %w[active archived all].freeze
    BEST_CONFIG_TIER_SQL =
      "CASE " \
      "WHEN feed_impressions_count >= #{FeedConfig::LOW_IMPRESSION_COUNT.to_i} THEN 0 " \
      "WHEN feed_impressions_count > 0 THEN 1 " \
      "ELSE 2 " \
      "END".freeze
    BEST_CONFIG_ORDER_SQL = Arel.sql(
      "#{BEST_CONFIG_TIER_SQL} ASC, feed_success_score DESC NULLS LAST, id ASC",
    ).freeze
    BEST_BY_BUCKET_ORDER_SQL = Arel.sql(
      "targeting_bucket ASC, #{BEST_CONFIG_TIER_SQL} ASC, feed_success_score DESC NULLS LAST, id ASC",
    ).freeze

    # Renders the feed configurations admin dashboard with bucket stats, pool badges, and paginated records.
    def index
      @selected_bucket = params[:filter] if FeedConfig::TARGETING_BUCKETS.include?(params[:filter])
      @status_mode = VALID_STATUS_MODES.include?(params[:mode]) ? params[:mode] : "active"

      @bucket_stats = build_bucket_stats
      @total_active_count = @bucket_stats.values.sum { |s| s[:active_count] }
      @total_archived_count = @bucket_stats.values.sum { |s| s[:archived_count] }

      @best_feed_config = if @selected_bucket
                            @bucket_stats.dig(@selected_bucket, :best_config)
                          else
                            select_best_config(@bucket_stats.values.filter_map { |s| s[:best_config] })
                          end
      @bucket_best_ids = @bucket_stats.values.filter_map { |s| s[:best_config]&.id }
      @top_pool_ids, @new_pool_ids = compute_active_pool_ids(@selected_bucket)

      base_scope = status_filtered_scope
      base_scope = base_scope.for_targeting_bucket(@selected_bucket) if @selected_bucket

      order_clause = case params[:sort]
                     when "newest"
                       { created_at: :desc, feed_success_score: :desc }
                     when "impressions"
                       { feed_impressions_count: :desc, feed_success_score: :desc }
                     else
                       { feed_success_score: :desc, created_at: :desc }
                     end

      @total_pages = (filtered_total_count.to_f / PER_PAGE).ceil
      @feed_configs = base_scope.order(order_clause).page(params[:page]).per(PER_PAGE)
    end

    # Displays a single feed configuration and its pool membership status within its targeting bucket.
    def show
      @feed_config = FeedConfig.find(params[:id])
      if @feed_config.archived?
        @in_top_pool = false
        @in_new_pool = false
        return
      end

      bucket_scope = FeedConfig.active.for_targeting_bucket(@feed_config.targeting_bucket)
      @bucket_best_config = best_feed_config(bucket_scope)
      top_ids, new_ids = compute_active_pool_ids(@feed_config.targeting_bucket)
      @in_top_pool = top_ids.include?(@feed_config.id)
      @in_new_pool = new_ids.include?(@feed_config.id)
    end

    # Initializes a new feed configuration pre-populated from a cloned or best-performing config.
    def new
      requested_bucket = if FeedConfig::NON_ALL_TARGETING_BUCKETS.include?(params[:filter])
                           params[:filter]
                         end

      source_config = if params[:clone_from_id].present?
                        FeedConfig.find_by(id: params[:clone_from_id])
                      elsif requested_bucket
                        best_feed_config(FeedConfig.active.for_targeting_bucket(requested_bucket)) || best_feed_config
                      else
                        best_feed_config
                      end
      @has_source_config = source_config.present?

      @feed_config = if source_config
                       source_config.dup.tap do |config|
                         config.feed_impressions_count = 0
                         config.feed_impression_users_count = 0
                         config.feed_repeat_visits_count = 0
                         config.feed_success_score = 0.0
                         config.archived = false
                         if requested_bucket
                           config.targeting_bucket = requested_bucket
                         elsif config.targeting_bucket == FeedConfig::BUCKET_ALL
                           config.targeting_bucket = FeedConfig::BUCKET_FEED_CASUAL_USER
                         end
                       end
                     else
                       FeedConfig.new(targeting_bucket: requested_bucket || FeedConfig::BUCKET_FEED_CASUAL_USER)
                     end
    end

    def create
      @feed_config = FeedConfig.new(feed_config_params)

      if @feed_config.save
        flash[:success] = "Feed Config ##{@feed_config.id} successfully created."
        redirect_to admin_feed_config_path(@feed_config)
      else
        flash[:danger] = @feed_config.errors.full_messages.to_sentence
        render :new
      end
    end

    def destroy
      @feed_config = FeedConfig.find(params[:id])

      if @feed_config.destroy
        flash[:success] = "Feed Config ##{@feed_config.id} deleted."
      else
        flash[:danger] = "Failed to delete Feed Config ##{@feed_config.id}."
      end
      redirect_to admin_feed_configs_path
    end

    private

    def status_filtered_scope
      case @status_mode
      when "archived"
        FeedConfig.archived
      when "all"
        FeedConfig.all
      else
        FeedConfig.active
      end
    end

    # Builds active/archived counts and best-performing config per targeting bucket in two queries.
    def build_bucket_stats
      counts = FeedConfig.group(:archived, :targeting_bucket).count
      best_by_bucket = FeedConfig.active
        .select("DISTINCT ON (targeting_bucket) feed_configs.*")
        .order(BEST_BY_BUCKET_ORDER_SQL)
        .index_by(&:targeting_bucket)

      FeedConfig::TARGETING_BUCKETS.index_with do |bucket|
        {
          active_count: counts[[false, bucket]] || 0,
          archived_count: counts[[true, bucket]] || 0,
          best_config: best_by_bucket[bucket]
        }
      end
    end

    # Returns the already-computed record count for the active bucket and status filter.
    def filtered_total_count
      bucket_stat = @bucket_stats[@selected_bucket]
      active_count = @selected_bucket ? bucket_stat&.dig(:active_count).to_i : @total_active_count
      archived_count = @selected_bucket ? bucket_stat&.dig(:archived_count).to_i : @total_archived_count
      case @status_mode
      when "archived" then archived_count
      when "all" then active_count + archived_count
      else active_count
      end
    end

    # Computes top-scoring and newest low-impression pool IDs across active buckets in a single window query.
    def compute_active_pool_ids(selected_bucket = nil)
      return [[], []] if @status_mode == "archived"

      limit = FeedConfig::TOP_POOL_LIMIT.to_i
      low_impressions = FeedConfig::LOW_IMPRESSION_COUNT.to_i
      scope = selected_bucket ? FeedConfig.active.for_targeting_bucket(selected_bucket) : FeedConfig.active
      tier_order = "PARTITION BY targeting_bucket " \
                   "ORDER BY #{BEST_CONFIG_TIER_SQL} ASC, feed_success_score DESC NULLS LAST, id ASC"
      new_order = "PARTITION BY targeting_bucket, (feed_impressions_count < #{low_impressions}) " \
                  "ORDER BY created_at DESC, id DESC"

      ranked_scope = scope.select(
        :id,
        :feed_impressions_count,
        "#{BEST_CONFIG_TIER_SQL} AS tier",
        "FIRST_VALUE(#{BEST_CONFIG_TIER_SQL}) OVER (#{tier_order}) AS min_tier",
        "ROW_NUMBER() OVER (#{tier_order}) AS top_rn",
        "ROW_NUMBER() OVER (#{new_order}) AS new_rn",
      )

      top_cond = "(tier < 2 AND tier = min_tier AND top_rn <= #{limit})"
      new_cond = "(feed_impressions_count < #{low_impressions} AND new_rn <= #{limit})"

      top_ids = []
      new_ids = []
      FeedConfig.unscoped.from(ranked_scope, :ranked).where("#{top_cond} OR #{new_cond}")
        .pluck(:id, Arel.sql(top_cond), Arel.sql(new_cond)).each do |id, in_top, in_new|
          top_ids << id if in_top
          new_ids << id if in_new
        end
      [top_ids, new_ids]
    end

    # Selects the highest-priority feed configuration in memory using the same tier and score ordering as SQL.
    def select_best_config(configs)
      configs.min_by do |config|
        impressions = config.feed_impressions_count.to_i
        tier = if impressions >= FeedConfig::LOW_IMPRESSION_COUNT
                 0
               elsif impressions.positive?
                 1
               else
                 2
               end
        score_sort = config.feed_success_score.nil? ? [1, 0.0] : [0, -config.feed_success_score.to_f]
        [tier, score_sort, config.id]
      end
    end

    # Returns the single best-performing feed configuration from the given scope in one query.
    def best_feed_config(scope = FeedConfig.active)
      scope.order(BEST_CONFIG_ORDER_SQL).first
    end

    def feed_config_params
      params.require(:feed_config).permit(
        :ai_disclosure_matching_weight,
        :autonomous_ai_penalty_weight,
        :clickbait_score_weight,
        :comment_recency_weight,
        :comment_score_weight,
        :compellingness_score_weight,
        :favorited_weight,
        :featured_weight,
        :feed_lookback_hours,
        :feed_success_weight,
        :follow_status_weight,
        :general_past_day_bonus_weight,
        :label_match_weight,
        :language_match_weight,
        :lookback_window_weight,
        :organization_follow_weight,
        :precomputed_selections_weight,
        :published_at_diversity_weight,
        :published_today_weight,
        :randomness_weight,
        :recency_weight,
        :recent_article_suppression_rate,
        :recent_page_views_shuffle_weight,
        :recent_subforem_weight,
        :recent_tag_count_max,
        :recent_tag_count_min,
        :all_time_tag_count_max,
        :all_time_tag_count_min,
        :recently_active_past_day_bonus_weight,
        :score_weight,
        :semantic_candidate_limit,
        :semantic_similarity_weight,
        :shuffle_weight,
        :status_weight,
        :subforem_follow_weight,
        :tag_follow_weight,
        :targeting_bucket,
        :user_follow_weight,
      )
    end
  end
end
