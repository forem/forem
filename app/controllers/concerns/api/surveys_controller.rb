module Api
  module SurveysController
    extend ActiveSupport::Concern

    DEFAULT_PER_PAGE = 30

    included do
      before_action :authenticate_with_api_key_or_current_user!
      before_action :authorize_admin
      before_action :set_survey, only: %i[show responses]
    end

    def index
      per_page = (params[:per_page] || DEFAULT_PER_PAGE).to_i
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

    def responses
      since = Time.iso8601(params[:since]).in_time_zone if params[:since].present?

      per_page = (params[:per_page] || DEFAULT_PER_PAGE).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      @poll_votes = PollVote.joins(:poll)
        .where(polls: { survey_id: @survey.id })
        .then { |q| since ? q.where("poll_votes.created_at > ?", since) : q }
        .includes(:user)
        .order(Arel.sql("poll_votes.created_at ASC"))
        .page(page).per(num)

      @text_responses = PollTextResponse.joins(:poll)
        .where(polls: { survey_id: @survey.id })
        .then { |q| since ? q.where("poll_text_responses.created_at > ?", since) : q }
        .includes(:user)
        .order(Arel.sql("poll_text_responses.created_at ASC"))
        .page(page).per(num)
    rescue ArgumentError
      error_unprocessable_entity("Invalid since timestamp")
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

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end
  end
end
