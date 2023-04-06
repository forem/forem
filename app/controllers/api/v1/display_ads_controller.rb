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

      def create
        @display_ad = DisplayAd.new(permitted_params)
        result = @display_ad.save
        render json: @display_ad, status: (result ? :ok : :unprocessable_entity)
      rescue ArgumentError => e
        # enums raise ArgumentError exceptions on unexpected inputs!
        render json: { error: e }, status: :unprocessable_entity
      end

      def update
        @display_ad = DisplayAd.find(params[:id])
        result = @display_ad.update(permitted_params)
        render json: @display_ad, status: (result ? :ok : :unprocessable_entity)
      rescue ArgumentError => e
        # enums raise ArgumentError exceptions on unexpected inputs!
        render json: { error: e }, status: :unprocessable_entity
      end

      def unpublish
        @display_ad = DisplayAd.find(params[:id])
        result = @display_ad.update(published: false)
        if result
          head :no_content
        else
          render json: @display_ad, status: :unprocessable_entity
        end
      end

      private

      def require_admin
        authorize DisplayAd, :access?, policy_class: InternalPolicy
      end

      def permitted_params
        params.permit :approved, :body_markdown, :creator_id, :display_to,
                      :name, :organization_id, :placement_area, :published,
                      :tag_list, :type_of, :exclude_article_ids
      end
    end
  end
end
