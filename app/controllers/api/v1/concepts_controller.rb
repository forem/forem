module Api
  module V1
    class ConceptsController < Api::V1::ApiController
      before_action :authenticate_with_api_key_or_current_user!
      before_action :set_concept, only: [:show]
      before_action :authorize_concept_access!, only: [:show]

      def index
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [params.fetch(:per_page, 50).to_i, 100].min
        days = [params.fetch(:days, 7).to_i, 1].max
        start_date = Date.today - days.days

        @concepts = if current_user.super_admin?
                      Concept.all
                    else
                      current_user.accessible_concepts
                    end

        @concepts = @concepts.select(:id, :name, :slug, :description, :parent_id, :created_at, :updated_at)
                             .order(:name)
                             .page(page)
                             .per(per_page)

        concept_ids = @concepts.map(&:id)
        metrics_by_concept = if concept_ids.any?
                               ConceptDailyMetric.where(concept_id: concept_ids)
                                                  .where("date >= ?", start_date)
                                                  .order(date: :desc)
                                                  .group_by(&:concept_id)
                             else
                               {}
                             end

        serialized_concepts = @concepts.map do |concept|
          metrics = metrics_by_concept[concept.id] || []
          concept.as_json(only: %i[id name slug description parent_id created_at updated_at]).merge(
            "daily_metrics" => metrics.map { |m| m.as_json(only: %i[date articles_count comments_count page_views reactions_count popularity_score]) }
          )
        end

        render json: serialized_concepts
      end

      def show
        days = [params.fetch(:days, 7).to_i, 1].max
        start_date = Date.today - days.days

        metrics = @concept.concept_daily_metrics
                          .where("date >= ?", start_date)
                          .order(date: :desc)

        serialized_concept = @concept.as_json(only: %i[id name slug description parent_id created_at updated_at]).merge(
          "daily_metrics" => metrics.map { |m| m.as_json(only: %i[date articles_count comments_count page_views reactions_count popularity_score]) }
        )

        render json: serialized_concept
      end

      private

      def set_concept
        @concept = Concept.select(:id, :name, :slug, :description, :parent_id, :created_at, :updated_at).find(params[:id])
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
