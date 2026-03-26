module Api
  module SurveysController
    extend ActiveSupport::Concern

    DEFAULT_PER_PAGE = 30

    included do
      before_action :authenticate_with_api_key_or_current_user!
      before_action :authorize_admin
      before_action :set_survey, only: %i[show poll_votes poll_text_responses]
    end

    def index
      num = [per_page, per_page_max].min

      @surveys = Survey
        .then do |q|
          if params[:active].present?
            q.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
          else
            q
          end
        end
        .page(params[:page]).per(num)
    end

    def show; end

    def poll_votes
      @poll_votes = paginated_survey_responses(PollVote)
    end

    def poll_text_responses
      @poll_text_responses = paginated_survey_responses(PollTextResponse)
    end

    private

    def set_survey
      @survey = Survey.find_by(id: params[:id_or_slug]) ||
        Survey.find_by(slug: params[:id_or_slug]) ||
        Survey.find_by(old_slug: params[:id_or_slug]) ||
        Survey.find_by(old_old_slug: params[:id_or_slug])

      raise ActiveRecord::RecordNotFound unless @survey
    end

    def authorize_admin
      authorize Survey, :access?, policy_class: InternalPolicy
    end

    def paginated_survey_responses(model_class)
      after_id = params[:after].to_i if params[:after].present?

      num = [per_page, per_page_max].min

      model_class.joins(:poll)
        .where(polls: { survey_id: @survey.id })
        .then { |q| after_id ? q.where(model_class.arel_table[:id].gt(after_id)) : q }
        .includes(:user)
        .order(id: :asc)
        .limit(num)
    end

    def per_page
      return params[:per_page].to_i if params[:per_page]

      DEFAULT_PER_PAGE
    end

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end
  end
end
