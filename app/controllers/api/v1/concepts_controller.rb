module Api
  module V1
    class ConceptsController < Api::V1::ApiController
      before_action :authenticate_with_api_key_or_current_user!
      before_action :set_concept, only: %i[show update articles]
      before_action :authorize_concept_access!, only: %i[show update articles]

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

        @concepts = @concepts.select(:id, :name, :slug, :description, :parent_id, :score, :similarity_threshold, :created_at, :updated_at)
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
          concept.as_json(only: %i[id name slug description parent_id score similarity_threshold created_at updated_at]).merge(
            "daily_metrics" => metrics.map { |m| m.as_json(only: %i[date articles_count comments_count page_views reactions_count popularity_score]) }
          )
        end

        render json: serialized_concepts
      end

      def show
        render json: serialized_concept_response(@concept)
      end

      def update
        @concept.assign_attributes(concept_update_params)

        if @concept.will_save_change_to_description?
          Concepts::AnchorGenerator.new(@concept).call if @concept.name.present?
        end

        if @concept.save
          if @concept.saved_change_to_description? || @concept.saved_change_to_similarity_threshold?
            Concepts::BackfillClassifierWorker.perform_async(@concept.id)
          end
          render json: serialized_concept_response(@concept)
        else
          render json: { errors: @concept.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def articles
        per_page = (params[:per_page] || 10).to_i
        num = [per_page, per_page_max].min
        page = params[:page] || 1

        sort_by = params[:sort] == "score" ? "articles.score DESC" : "concept_memberships.distance ASC, articles.score DESC"

        @articles = Article.published
                           .joins(:concept_memberships)
                           .where(concept_memberships: { concept_id: @concept.id })
                           .select(Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION)
                           .includes(user: :profile)
                           .order(sort_by)
                           .page(page)
                           .per(num)
                           .decorate

        set_surrogate_key_header @concept.record_key, *@articles.map(&:record_key)
        render "api/v0/articles/index", formats: :json
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

      def concept_update_params
        params.require(:concept).permit(:score, :description, :similarity_threshold)
      end

      def per_page_max
        (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
      end

      def serialized_concept_response(concept)
        days = [params.fetch(:days, 7).to_i, 1].max
        start_date = Date.today - days.days

        metrics = concept.concept_daily_metrics
                         .where("date >= ?", start_date)
                         .order(date: :desc)

        concept.as_json(only: %i[id name slug description parent_id score similarity_threshold created_at updated_at]).merge(
          "daily_metrics" => metrics.map { |m| m.as_json(only: %i[date articles_count comments_count page_views reactions_count popularity_score]) },
          "top_articles" => concept.top_articles(3).map { |a| a.as_json(only: %i[id title slug score published_at]) }
        )
      end
    end
  end
end
