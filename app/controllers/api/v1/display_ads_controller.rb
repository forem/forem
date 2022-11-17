module Api
  module V1
    class DisplayAdsController < ApiController
      before_action :authenticate_with_api_key!
      before_action :require_admin

      def index
        @display_ads = DisplayAd.order(id: :desc).page(params[:page]).per(50)
        @display_ads = @display_ads.search_ads(params[:search]) if params[:search].present?
        render json: @display_ads
      end

      def show
        @display_ad = DisplayAd.find(params[:id])
        render json: @display_ad
      end

      private

      def require_admin
        authorize DisplayAd, :access?, policy_class: InternalPolicy
      end
    end
  end
end
