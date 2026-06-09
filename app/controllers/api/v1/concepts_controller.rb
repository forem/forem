module Api
  module V1
    class ConceptsController < Api::V1::ApiController
      before_action :authenticate_with_api_key_or_current_user!
      before_action :set_concept, only: [:show]
      before_action :authorize_concept_access!, only: [:show]

      def index
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [params.fetch(:per_page, 50).to_i, 100].min

        @concepts = if current_user.super_admin?
                      Concept.all
                    else
                      current_user.accessible_concepts
                    end

        @concepts = @concepts.select(:id, :name, :slug, :description, :parent_id, :similarity_threshold, :max_lookback_days, :created_at, :updated_at)
                             .order(:name)
                             .page(page)
                             .per(per_page)

        render json: @concepts
      end

      def show
        render json: @concept
      end

      private

      def set_concept
        @concept = Concept.find(params[:id])
      end

      def authorize_concept_access!
        return if current_user.super_admin?
        return if current_user.accessible_concepts.exists?(id: @concept.id)

        error_unauthorized
      end

      def current_user
        @user
      end
    end
  end
end
