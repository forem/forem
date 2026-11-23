module Admin
  class BillboardCampaignsController < Admin::ApplicationController
    layout "admin"

    def index
      @campaigns = BillboardCampaign.select(:id, :name).order(id: :desc).page(params[:page]).per(50).without_count.load
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
      params.require(:billboard_campaign).permit(:name, :expires_at, :max_impressions_count, :max_clicks_count,
                                                 :ideal_daily_impressions)
    end

    def authorize_admin
      authorize Billboard, :access?, policy_class: InternalPolicy
    end
  end
end
