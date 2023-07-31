module Api
  module V1
    class BillboardsController < ApiController
      before_action :authenticate_with_api_key!
      before_action :require_admin

      def index
        @billboards = DisplayAd.order(id: :desc).page(params[:page]).per(50)
        @billboards = @billboards.search_ads(params[:search]) if params[:search].present?
        render json: @billboards
      end

      def show
        @billboard = DisplayAd.find(params[:id])
        render json: @billboard
      end

      def create
        @billboard = DisplayAd.new(permitted_params)
        result = @billboard.save
        render json: @billboard, status: (result ? :ok : :unprocessable_entity)
      rescue ArgumentError => e
        # enums raise ArgumentError exceptions on unexpected inputs!
        render json: { error: e }, status: :unprocessable_entity
      end

      def update
        @billboard = DisplayAd.find(params[:id])
        result = @billboard.update(permitted_params)
        render json: @billboard, status: (result ? :ok : :unprocessable_entity)
      rescue ArgumentError => e
        # enums raise ArgumentError exceptions on unexpected inputs!
        render json: { error: e }, status: :unprocessable_entity
      end

      def unpublish
        @billboard = DisplayAd.find(params[:id])
        result = @billboard.update(published: false)
        if result
          head :no_content
        else
          render json: @billboard, status: :unprocessable_entity
        end
      end

      private

      def require_admin
        authorize DisplayAd, :access?, policy_class: InternalPolicy
      end

      def permitted_params
        params.permit :approved, :body_markdown, :creator_id, :display_to,
                      :name, :organization_id, :placement_area, :published,
                      :tag_list, :type_of, :exclude_article_ids,
                      :audience_segment_type, :audience_segment_id,
                      :priority
      end
    end
  end
end
