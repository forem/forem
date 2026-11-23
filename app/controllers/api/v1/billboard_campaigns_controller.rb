module Api
  module V1
    class BillboardCampaignsController < ApiController
      before_action :authenticate_with_api_key!
      before_action :require_admin

      def index
        render json: BillboardCampaign.order(id: :desc).page(params[:page]).per(50)
      end

      def show
        render json: BillboardCampaign.find(params[:id])
      end

      def create
        campaign = BillboardCampaign.create!(permitted_params)
        log_audit("api_billboard_campaign_create", campaign)
        render json: campaign, status: :created
      end

      def update
        campaign = BillboardCampaign.find(params[:id])
        missing = []
        campaign.with_billboards_locked do
          campaign.assign_attributes(permitted_params)
          missing = BillboardCampaignPolicy.new(@user, campaign).missing_sub_permissions(:save)
          campaign.save! if missing.empty?
        end
        return render_missing_sub_permissions(missing) if missing.any?

        log_audit("api_billboard_campaign_update", campaign)
        render json: campaign
      end

      private

      def require_admin
        authorize Billboard, :access?, policy_class: InternalPolicy
      end

      def render_missing_sub_permissions(missing)
        render json: { error: SubPermissions.missing_message(Billboard, missing), status: 403 }, status: :forbidden
      end

      def log_audit(action, campaign)
        Audit::Logger.log(:admin_api, @user, { "action" => action, "billboard_campaign_id" => campaign.id })
      end

      def permitted_params
        params.permit :name, :organization_id, :expires_at, :max_impressions_count, :max_clicks_count,
                      :ideal_daily_impressions
      end
    end
  end
end
