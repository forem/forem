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
      poll_ids = @survey.polls.ids
      since = params[:since].present? ? Time.zone.parse(params[:since]) : nil

      per_page = (params[:per_page] || DEFAULT_PER_PAGE).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      @poll_votes = PollVote.where(poll_id: poll_ids)
        .then { |q| since ? q.where("created_at > ?", since) : q }
        .includes(:user)
        .order(created_at: :asc)
        .page(page).per(num)

      @text_responses = PollTextResponse.where(poll_id: poll_ids)
        .then { |q| since ? q.where("created_at > ?", since) : q }
        .includes(:user)
        .order(created_at: :asc)
        .page(page).per(num)
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
