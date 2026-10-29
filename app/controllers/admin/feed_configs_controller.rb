module Admin
  class FeedConfigsController < Admin::ApplicationController
    layout "admin"

    VALID_STATUS_MODES = %w[active archived all].freeze

    def index
      @selected_bucket = params[:filter] if FeedConfig::TARGETING_BUCKETS.include?(params[:filter])
      @status_mode = VALID_STATUS_MODES.include?(params[:mode]) ? params[:mode] : "active"

      @bucket_stats = build_bucket_stats
      @total_active_count = @bucket_stats.values.sum { |s| s[:active_count] }
      @total_archived_count = @bucket_stats.values.sum { |s| s[:archived_count] }

      active_bucket_scope = if @selected_bucket
                              FeedConfig.active.for_targeting_bucket(@selected_bucket)
                            else
                              FeedConfig.active
                            end
      @best_feed_config = best_feed_config(active_bucket_scope)
      @bucket_best_ids = @bucket_stats.values.filter_map { |s| s[:best_config]&.id }
      @top_pool_ids = compute_pool_ids(:top, @selected_bucket)
      @new_pool_ids = compute_pool_ids(:new, @selected_bucket)

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

      @feed_configs = base_scope.order(order_clause).page(params[:page]).per(25)
    end

    def show
      @feed_config = FeedConfig.find(params[:id])
      bucket_scope = FeedConfig.active.for_targeting_bucket(@feed_config.targeting_bucket)
      @bucket_best_config = best_feed_config(bucket_scope)
      @in_top_pool = !@feed_config.archived? && top_pool_ids(bucket_scope).include?(@feed_config.id)
      @in_new_pool = !@feed_config.archived? && new_pool_ids(bucket_scope).include?(@feed_config.id)
    end

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

      @feed_config = if source_config
                       source_config.dup.tap do |config|
                         config.feed_impressions_count = 0
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

    def build_bucket_stats
      active_counts = FeedConfig.active.group(:targeting_bucket).count
      archived_counts = FeedConfig.archived.group(:targeting_bucket).count

      FeedConfig::TARGETING_BUCKETS.index_with do |bucket|
        scope = FeedConfig.active.for_targeting_bucket(bucket)
        {
          active_count: active_counts[bucket] || 0,
          archived_count: archived_counts[bucket] || 0,
          best_config: best_feed_config(scope)
        }
      end
    end

    def compute_pool_ids(pool_type, selected_bucket)
      buckets = selected_bucket ? [selected_bucket] : FeedConfig::TARGETING_BUCKETS
      buckets.flat_map do |bucket|
        scope = FeedConfig.active.for_targeting_bucket(bucket)
        pool_type == :top ? top_pool_ids(scope) : new_pool_ids(scope)
      end
    end

    def top_pool_ids(scope = FeedConfig.active)
      ids = scope
        .where("feed_impressions_count >= ?", FeedConfig::LOW_IMPRESSION_COUNT)
        .order(feed_success_score: :desc)
        .limit(FeedConfig::TOP_POOL_LIMIT)
        .ids
      return ids if ids.any?

      scope
        .where("feed_impressions_count > 0")
        .order(feed_success_score: :desc)
        .limit(FeedConfig::TOP_POOL_LIMIT)
        .ids
    end

    def new_pool_ids(scope = FeedConfig.active)
      scope
        .where("feed_impressions_count < ?", FeedConfig::LOW_IMPRESSION_COUNT)
        .order(created_at: :desc)
        .limit(FeedConfig::TOP_POOL_LIMIT)
        .ids
    end

    def best_feed_config(scope = FeedConfig.active)
      scope
        .where("feed_impressions_count >= ?", FeedConfig::LOW_IMPRESSION_COUNT)
        .order("feed_success_score DESC NULLS LAST")
        .first ||
        scope.where("feed_impressions_count > 0").order("feed_success_score DESC NULLS LAST").first ||
        scope.order("feed_success_score DESC NULLS LAST").first ||
        scope.last
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
