module Api
  module V1
    class RecommendedArticlesListsController < ApiController
      before_action :authenticate_with_api_key!
      before_action :require_admin

      rescue_from ArgumentError, with: :error_unprocessable_entity

      def index
        @recommended_articles_lists = RecommendedArticlesList.order(id: :desc).page(params[:page]).per(50)
        if params[:search].present?
          @recommended_articles_lists = @recommended_articles_lists.search(params[:search])
        end
        render json: @recommended_articles_lists
      end

      def show
        @recommended_articles_list = RecommendedArticlesList.find(params[:id])
        render json: @recommended_articles_list
      end

      def create
        # Actually uspert than a pure create
        # We upsert by user_id and placement_area
        # In the future we may want to allow multiple lists per user and placement_area,
        # and we will use a special param for that.
        @recommended_articles_list = RecommendedArticlesList.where(
          user_id: permitted_params[:user_id],
          placement_area: permitted_params[:placement_area],
        ).first_or_initialize
        @recommended_articles_list.assign_attributes(permitted_params)
        @recommended_articles_list.save!
        render json: @recommended_articles_list, status: :created
      end

      def update
        @recommended_articles_list = RecommendedArticlesList.find(params[:id])
        @recommended_articles_list.update!(permitted_params)
        render json: @recommended_articles_list
      end

      private

      def require_admin
        authorize RecommendedArticlesList, :access?, policy_class: InternalPolicy
      end

      def permitted_params
        params.permit :name, :placement_area, :expires_at, :user_id,
                      :article_ids, article_ids: []
      end
    end
  end
end
