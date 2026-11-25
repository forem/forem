module Admin
  class BillboardsController < Admin::ApplicationController
    layout "admin"

    INDEX_COLUMNS = %i[
      id name placement_area display_to type_of published approved priority weight
      success_rate impressions_count clicks_count seconds_visible
      max_impressions_count max_clicks_count expires_at
      billboard_campaign_id organization_id cached_tag_list
      render_mode isolate_content updated_at
    ].freeze
    EVENT_COLUMNS = %i[id display_ad_id user_id category created_at].freeze
    RECENT_EVENTS_WINDOW = 30.days
    CAMPAIGN_FILTER_LIMIT = 200

    SORT_CLAUSES = {
      "newest" => { id: :desc },
      "impressions" => Arel.sql("COALESCE(display_ads.impressions_count, 0) DESC, display_ads.id DESC"),
      "clicks" => Arel.sql("COALESCE(display_ads.clicks_count, 0) DESC, display_ads.id DESC"),
      "success_rate" => Arel.sql("COALESCE(display_ads.success_rate, 0) DESC, display_ads.id DESC"),
      "weight" => Arel.sql("COALESCE(display_ads.weight, 0) DESC, display_ads.id DESC"),
      "expiring_soon" => Arel.sql("display_ads.expires_at ASC NULLS LAST, display_ads.id DESC"),
      "updated" => { updated_at: :desc, id: :desc }
    }.freeze

    def index
      @now = Time.current
      @overview = Billboards::AdminAnalytics.overview_summary(now: @now)
      @campaigns_for_filter = load_campaigns_list(selected_id: params[:billboard_campaign_id])
      @campaigns_by_id = @campaigns_for_filter.index_by(&:id)

      billboards = apply_filters(Billboard.select(*INDEX_COLUMNS), now: @now)
      billboards = apply_sort(billboards)
      @billboards = billboards.page(params[:page]).per(50).without_count.load

      preload_index_associations(@billboards)
    end

    def show
      @now = Time.current
      @billboard = Billboard.find(params[:id])
      @campaign = @billboard.billboard_campaign
      @campaign_rollup = if @campaign
                           Billboards::AdminAnalytics.campaign_rollups([@campaign.id], now: @now)[@campaign.id] ||
                             Billboards::AdminAnalytics::EMPTY_ROLLUP
                         end
      @events = @billboard.billboard_events
        .select(*EVENT_COLUMNS)
        .where("created_at >= ?", RECENT_EVENTS_WINDOW.ago)
        .where.not(user_id: nil)
        .where.not(category: "impression")
        .order(created_at: :desc)
        .limit(25)
        .to_a
      ActiveRecord::Associations::Preloader.new(
        records: @events, associations: :user, scope: User.select(:id, :username),
      ).call
    end

    def new
      @billboard = Billboard.new
      if params[:billboard_campaign_id].to_s.match?(/\A[1-9]\d*\z/)
        @billboard.billboard_campaign_id = params[:billboard_campaign_id].to_i
      end
      load_campaigns_for_select
    end

    def edit
      @billboard = Billboard.find(params[:id])
      load_campaigns_for_select
    end

    def create
      @billboard = Billboard.new(billboard_params)
      @billboard.creator = current_user
      missing = []
      saved = Billboard.transaction do
        @billboard.lock_affected_campaigns!
        missing = missing_sub_permissions(:save)
        @billboard.save if missing.empty?
      end
      if missing.any?
        load_campaigns_for_select
        return render_missing_sub_permissions(:new, missing)
      end

      if saved
        flash[:success] = I18n.t("admin.billboards_controller.created")
        redirect_to edit_admin_billboard_path(@billboard.id)
      else
        load_campaigns_for_select
        flash[:danger] = @billboard.errors_as_sentence
        render :new
      end
    end

    def update
      @billboard = Billboard.find(params[:id])
      missing = []
      saved = false
      @billboard.with_lock do
        @billboard.assign_attributes(billboard_params)
        @billboard.lock_affected_campaigns!
        missing = missing_sub_permissions(:save)
        saved = @billboard.save if missing.empty?
      end
      if missing.any?
        load_campaigns_for_select
        return render_missing_sub_permissions(:edit, missing)
      end

      if saved
        flash[:success] = I18n.t("admin.billboards_controller.updated")
        redirect_to edit_admin_billboard_path(params[:id])
      else
        load_campaigns_for_select
        flash[:danger] = @billboard.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @billboard = Billboard.find(params[:id])
      missing = []
      destroyed = false
      @billboard.with_lock do
        @billboard.lock_affected_campaigns!
        missing = missing_sub_permissions(:destroy)
        destroyed = @billboard.destroy if missing.empty?
      end
      if missing.any?
        return render json: { error: SubPermissions.missing_message(Billboard, missing) }, status: :forbidden
      end

      if destroyed
        render json: { message: I18n.t("admin.billboards_controller.deleted") }, status: :ok
      else
        render json: { error: I18n.t("admin.billboards_controller.wrong") }, status: :unprocessable_entity
      end
    end

    private

    def apply_filters(scope, now:)
      scope = apply_search_filter(scope)
      scope = apply_status_filter(scope, now: now)
      scope = apply_campaign_filter(scope)
      scope = apply_targeting_filters(scope)
      apply_attribute_filters(scope)
    end

    def apply_search_filter(scope)
      term = params[:search].to_s.strip
      return scope if term.blank?

      numeric_id = term.delete_prefix("#")
      if numeric_id.match?(/\A[1-9]\d*\z/)
        scope.where(
          "display_ads.id = :id OR display_ads.name ILIKE :q " \
          "OR display_ads.processed_html ILIKE :q OR display_ads.placement_area ILIKE :q " \
          "OR display_ads.cached_tag_list ILIKE :q",
          id: numeric_id.to_i,
          q: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%",
        )
      else
        scope.where(
          "display_ads.name ILIKE :q OR display_ads.processed_html ILIKE :q " \
          "OR display_ads.placement_area ILIKE :q OR display_ads.cached_tag_list ILIKE :q",
          q: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%",
        )
      end
    end

    def apply_status_filter(scope, now:)
      case params[:status].to_s
      when "live"
        scope.where(approved: true, published: true)
          .where("display_ads.expires_at IS NULL OR display_ads.expires_at > ?", now)
          .where(Billboard::ACTIVE_CAMPAIGN_SQL, now)
      when "expired"
        scope.where(
          "(display_ads.expires_at IS NOT NULL AND display_ads.expires_at <= :now) " \
          "OR EXISTS (SELECT 1 FROM billboard_campaigns " \
          "WHERE billboard_campaigns.id = display_ads.billboard_campaign_id " \
          "AND billboard_campaigns.expires_at IS NOT NULL " \
          "AND billboard_campaigns.expires_at <= :now)",
          now: now,
        )
      when "capped"
        scope.where(
          "(display_ads.max_impressions_count > 0 " \
          "AND COALESCE(display_ads.impressions_count, 0) >= display_ads.max_impressions_count) " \
          "OR (display_ads.max_clicks_count > 0 " \
          "AND COALESCE(display_ads.clicks_count, 0) >= display_ads.max_clicks_count)",
        )
      when "draft"
        scope.where("display_ads.approved = FALSE OR display_ads.published = FALSE")
          .where("display_ads.expires_at IS NULL OR display_ads.expires_at > ?", now)
          .where(Billboard::ACTIVE_CAMPAIGN_SQL, now)
      else
        scope
      end
    end

    def apply_campaign_filter(scope)
      val = params[:billboard_campaign_id].to_s.strip
      return scope if val.blank?
      return scope.where(billboard_campaign_id: nil) if val == "none"
      return scope.where(billboard_campaign_id: val.to_i) if val.match?(/\A[1-9]\d*\z/)

      scope
    end

    def apply_targeting_filters(scope)
      area = params[:placement_area].to_s
      scope = scope.where(placement_area: area) if Billboard::ALLOWED_PLACEMENT_AREAS.include?(area)

      type = params[:type_of].to_s
      scope = scope.where(type_of: type) if Billboard.type_ofs.key?(type)

      display = params[:display_to].to_s
      scope = scope.where(display_to: display) if Billboard.display_tos.key?(display)

      tag = params[:tag].to_s.strip.delete_prefix("#").downcase
      scope = scope.where("display_ads.tags_array @> ARRAY[?]::text[]", tag) if tag.present?

      org_id = params[:organization_id].to_s.strip
      scope = scope.where(organization_id: org_id.to_i) if org_id.match?(/\A[1-9]\d*\z/)

      scope
    end

    def apply_attribute_filters(scope)
      case params[:priority].to_s
      when "true" then scope = scope.where(priority: true)
      when "false" then scope = scope.where(priority: false)
      end

      case params[:render_mode].to_s
      when "forem_markdown" then scope = scope.where(render_mode: :forem_markdown)
      when "raw" then scope = scope.where(render_mode: :raw)
      when "isolated" then scope = scope.where(render_mode: :raw, isolate_content: true)
      end

      scope
    end

    def apply_sort(scope)
      clause = SORT_CLAUSES.fetch(params[:sort].to_s, SORT_CLAUSES["newest"])
      scope.order(clause)
    end

    def preload_index_associations(billboards)
      return if billboards.empty?

      ActiveRecord::Associations::Preloader.new(
        records: billboards,
        associations: :billboard_campaign,
        scope: BillboardCampaign.select(:id, :name, :expires_at, :max_impressions_count, :max_clicks_count),
      ).call
      ActiveRecord::Associations::Preloader.new(
        records: billboards,
        associations: :organization,
        scope: Organization.select(:id, :name, :slug),
      ).call
    end

    def load_campaigns_for_select
      @campaigns_for_select = load_campaigns_list(selected_id: @billboard&.billboard_campaign_id)
    end

    def load_campaigns_list(selected_id: nil)
      campaigns = BillboardCampaign.select(:id, :name).order(id: :desc).limit(CAMPAIGN_FILTER_LIMIT).to_a
      requested_id = selected_id.to_s.strip
      return campaigns unless requested_id.match?(/\A[1-9]\d*\z/)

      campaign_id = requested_id.to_i
      return campaigns if campaigns.any? { |c| c.id == campaign_id }

      existing = BillboardCampaign.select(:id, :name).find_by(id: campaign_id)
      campaigns.unshift(existing) if existing
      campaigns
    end

    def billboard_params
      params.permit(:organization_id, :body_markdown, :placement_area, :target_geolocations,
                    :published, :approved, :name, :display_to, :tag_list, :type_of, :color,
                    :exclude_article_ids, :audience_segment_id, :priority, :weight, :dismissal_sku,
                    :browser_context, :exclude_role_names, :target_role_names, :include_subforem_ids,
                    :render_mode, :isolate_content, :template, :custom_display_label, :requires_cookies, :expires_at,
                    :special_behavior, :minimized_body_markdown, :billboard_campaign_id,
                    :max_impressions_count, :max_clicks_count)
    end

    def authorize_admin
      authorize Billboard, :access?, policy_class: InternalPolicy
    end

    def missing_sub_permissions(action)
      BillboardPolicy.new(current_user, @billboard).missing_sub_permissions(action)
    end

    def render_missing_sub_permissions(template, missing)
      flash.now[:danger] = SubPermissions.missing_message(Billboard, missing)
      render template, status: :forbidden
    end
  end
end
