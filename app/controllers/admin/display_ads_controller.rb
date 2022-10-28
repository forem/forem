module Admin
  class DisplayAdsController < Admin::ApplicationController
    layout "admin"

    after_action :bust_ad_caches, only: %i[create update destroy]

    def index
      @display_ads = DisplayAd.order(id: :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @display_ads = @display_ads.search_ads(params[:search])
    end

    def new
      @display_ad = DisplayAd.new
    end

    def edit
      @display_ad = DisplayAd.find(params[:id])
    end

    def create
      @display_ad = DisplayAd.new(display_ad_params)

      if @display_ad.save
        flash[:success] = I18n.t("admin.display_ads_controller.created")
        redirect_to edit_admin_display_ad_path(@display_ad.id)
      else
        flash[:danger] = @display_ad.errors_as_sentence
        render :new
      end
    end

    def update
      @display_ad = DisplayAd.find(params[:id])

      if @display_ad.update(display_ad_params)
        flash[:success] = I18n.t("admin.display_ads_controller.updated")
        redirect_to edit_admin_display_ad_path(params[:id])
      else
        flash[:danger] = @display_ad.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @display_ad = DisplayAd.find(params[:id])

      if @display_ad.destroy
        render json: { message: I18n.t("admin.display_ads_controller.deleted") }, status: :ok
      else
        render json: { error: I18n.t("admin.display_ads_controller.wrong") }, status: :unprocessable_entity
      end
    end

    private

    def display_ad_params
      params.permit(:organization_id, :body_markdown, :placement_area, :published, :approved, :name, :display_to,
                    :tag_list)
    end

    def authorize_admin
      authorize DisplayAd, :access?, policy_class: InternalPolicy
    end

    def bust_ad_caches
      EdgeCache::BustSidebar.call
    end
  end
end
