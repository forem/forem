module Admin
  class BillboardCampaignsController < Admin::ApplicationController
    layout "admin"

    INDEX_COLUMNS = %i[
      id name organization_id expires_at max_impressions_count max_clicks_count
      ideal_daily_impressions delivery_throttle_rate created_at updated_at
    ].freeze

    SORT_CLAUSES = {
      "newest" => { id: :desc },
      "expiring_soon" => Arel.sql("billboard_campaigns.expires_at ASC NULLS LAST, billboard_campaigns.id DESC"),
      "daily_target" => Arel.sql("billboard_campaigns.ideal_daily_impressions DESC, billboard_campaigns.id DESC"),
      "name" => Arel.sql("LOWER(billboard_campaigns.name) ASC, billboard_campaigns.id DESC")
    }.freeze

    def index
      @now = Time.current
      @overview = Billboards::AdminAnalytics.campaigns_overview_summary(now: @now)

      campaigns = apply_filters(BillboardCampaign.select(*INDEX_COLUMNS), now: @now)
      campaigns = apply_sort(campaigns)
      @campaigns = campaigns.page(params[:page]).per(50).without_count.load

      @rollups = Billboards::AdminAnalytics.campaign_rollups(@campaigns.map(&:id), now: @now)
      preload_organizations(@campaigns)
    end

    def show
      @now = Time.current
      @campaign = BillboardCampaign.find(params[:id])
      @organization = @campaign.organization
      @billboards = @campaign.billboards
        .select(*Admin::BillboardsController::INDEX_COLUMNS)
        .order(Arel.sql("CASE WHEN approved = TRUE AND published = TRUE THEN 0 ELSE 1 END ASC, " \
                        "COALESCE(impressions_count, 0) DESC, id DESC"))
        .to_a
      @rollup = Billboards::AdminAnalytics.rollup_from_billboards(@billboards, campaign: @campaign, now: @now)
      @daily_stats = Billboards::AdminAnalytics.campaign_daily_series(
        @billboards.map(&:id),
        days: Billboards::AdminAnalytics::DEFAULT_SERIES_DAYS,
        now: @now,
      )
      @placement_breakdown = Billboards::AdminAnalytics.placement_breakdown(
        @billboards,
        campaign_expired: @campaign.expired?(now: @now),
        now: @now,
      )
      @total_live_weight = @billboards
        .select { |bb| bb.approved? && bb.published? && !bb.expired?(now: @now) }
        .sum { |bb| bb.weight.to_f }
    end

    def new
      @campaign = BillboardCampaign.new
    end

    def edit
      @campaign = BillboardCampaign.find(params[:id])
    end

    def create
      @campaign = BillboardCampaign.new(campaign_params)
      respond_to_save(@campaign.save, :new)
    end

    def update
      @campaign = BillboardCampaign.find(params[:id])
      missing = []
      saved = @campaign.with_billboards_locked do
        @campaign.assign_attributes(campaign_params)
        missing = BillboardCampaignPolicy.new(current_user, @campaign).missing_sub_permissions(:save)
        @campaign.save if missing.empty?
      end
      if missing.any?
        flash.now[:danger] = SubPermissions.missing_message(Billboard, missing)
        return render :edit, status: :forbidden
      end

      respond_to_save(saved, :edit)
    end

    private

    def apply_filters(scope, now:)
      scope = apply_search_filter(scope)
      apply_status_filter(scope, now: now)
    end

    def apply_search_filter(scope)
      term = params[:search].to_s.strip
      return scope if term.blank?

      numeric_id = term.delete_prefix("#")
      if numeric_id.match?(/\A[1-9]\d*\z/)
        scope.where(
          "billboard_campaigns.id = :id OR billboard_campaigns.name ILIKE :q",
          id: numeric_id.to_i,
          q: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%",
        )
      else
        scope.where("billboard_campaigns.name ILIKE :q", q: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%")
      end
    end

    def apply_status_filter(scope, now:)
      capped_sql = <<~SQL.squish
        (billboard_campaigns.max_impressions_count > 0
          AND COALESCE((SELECT SUM(d.impressions_count) FROM display_ads d WHERE d.billboard_campaign_id = billboard_campaigns.id), 0) >= billboard_campaigns.max_impressions_count)
        OR (billboard_campaigns.max_clicks_count > 0
          AND COALESCE((SELECT SUM(d.clicks_count) FROM display_ads d WHERE d.billboard_campaign_id = billboard_campaigns.id), 0) >= billboard_campaigns.max_clicks_count)
      SQL

      live_member_sql = <<~SQL.squish
        EXISTS (
          SELECT 1 FROM display_ads d
          WHERE d.billboard_campaign_id = billboard_campaigns.id
            AND d.approved = TRUE AND d.published = TRUE
            AND (d.expires_at IS NULL OR d.expires_at > :now)
        )
      SQL

      case params[:status].to_s
      when "active"
        scope.where("billboard_campaigns.expires_at IS NULL OR billboard_campaigns.expires_at > ?", now)
          .where("NOT (#{capped_sql})")
          .where(live_member_sql, now: now)
      when "paced"
        scope.where("billboard_campaigns.ideal_daily_impressions > 0")
          .where("billboard_campaigns.expires_at IS NULL OR billboard_campaigns.expires_at > ?", now)
          .where("NOT (#{capped_sql})")
      when "throttled"
        scope.where("billboard_campaigns.ideal_daily_impressions > 0")
          .where("billboard_campaigns.delivery_throttle_rate < 1.0")
          .where("billboard_campaigns.expires_at IS NULL OR billboard_campaigns.expires_at > ?", now)
          .where("NOT (#{capped_sql})")
      when "idle"
        scope.where("billboard_campaigns.expires_at IS NULL OR billboard_campaigns.expires_at > ?", now)
          .where("NOT (#{capped_sql})")
          .where("NOT #{live_member_sql}", now: now)
      when "expired"
        scope.where("billboard_campaigns.expires_at IS NOT NULL AND billboard_campaigns.expires_at <= ?", now)
      when "capped"
        scope.where(capped_sql)
      else
        scope
      end
    end

    def apply_sort(scope)
      clause = SORT_CLAUSES.fetch(params[:sort].to_s, SORT_CLAUSES["newest"])
      scope.order(clause)
    end

    def preload_organizations(campaigns)
      return if campaigns.empty?

      ActiveRecord::Associations::Preloader.new(
        records: campaigns,
        associations: :organization,
        scope: Organization.select(:id, :name, :slug),
      ).call
    end

    def respond_to_save(saved, template)
      if saved
        Audit::Logger.log(:internal, current_user, {
                            "action" => "billboard_campaign_#{action_name}",
                            "billboard_campaign_id" => @campaign.id
                          })
        flash[:success] = t("views.admin.billboard_campaigns.saved")
        redirect_to edit_admin_billboard_campaign_path(@campaign), status: :see_other
      else
        flash.now[:danger] = @campaign.errors_as_sentence
        render template, status: :unprocessable_entity
      end
    end

    def campaign_params
      params.require(:billboard_campaign).permit(:name, :organization_id, :expires_at, :max_impressions_count,
                                                 :max_clicks_count, :ideal_daily_impressions)
    end

    def authorize_admin
      authorize Billboard, :access?, policy_class: InternalPolicy
    end
  end
end
