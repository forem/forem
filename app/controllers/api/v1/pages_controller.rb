module Api
  module V1
    class PagesController < ApiController
      before_action :authenticate!, except: %i[show index]
      before_action :require_admin, only: %i[create update destroy]

      def index
        @pages = Page.all
        render json: @pages
      end

      def show
        @page = Page.find params[:id]
        render json: @page
      end

      def create
        @page = Page.new permitted_params
        result = @page.save
        render json: @page, status: (result ? :ok : :unprocessable_entity)
      end

      def update
        @page = Page.find(params[:id])
        result = @page.update permitted_params
        render json: @page, status: (result ? :ok : :unprocessable_entity)
      end

      def destroy
        @page = Page.find(params[:id])
        result = @page.destroy
        render json: @page, status: (result ? :ok : :unprocessable_entity)
      end

      private

      def require_admin
        authorize Page, :access?, policy_class: InternalPolicy
      end

      def permitted_params
        if params[:social_image].present? && params[:social_image][:url].present?
          params[:remote_social_image_url] = params[:social_image][:url]
        end
        params.permit(*%i[title slug description is_top_level_path
                          body_json body_markdown body_html body_css remote_social_image_url template])
      end
    end
  end
end
