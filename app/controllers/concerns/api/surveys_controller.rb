module Api
  module SurveysController
    extend ActiveSupport::Concern

    DEFAULT_PER_PAGE = 30

    included do
      before_action :authenticate_with_api_key_or_current_user!
      before_action :authorize_admin
      before_action :set_survey, only: %i[show update destroy poll_votes poll_text_responses]
      before_action :normalize_survey_params!, only: %i[create update]
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

    def create
      @survey = Survey.new(survey_params)
      if @survey.save
        render :show, status: :created
      else
        render json: { errors: @survey.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @survey.update(survey_params)
        render :show, status: :ok
      else
        render json: { errors: @survey.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      if @survey.destroy
        head :no_content
      else
        render json: { errors: @survey.errors.full_messages }, status: :unprocessable_entity
      end
    end

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

    def survey_params
      params.require(:survey).permit(
        :title, :type_of, :active, :display_title, :allow_resubmission, :daily_email_distributions, :extra_email_context_paragraph,
        :target_response_count, :target_completion_date,
        polls_attributes: [
          :id, :prompt_markdown, :type_of, :position, :scale_min, :scale_max, :_destroy,
          poll_options_attributes: %i[id markdown supplementary_text position _destroy]
        ]
      )
    end

    def normalize_survey_params!
      return unless params[:survey].present?

      survey_hash = params[:survey].respond_to?(:to_unsafe_h) ? params[:survey].to_unsafe_h : params[:survey].to_h

      survey_type = survey_hash.delete("survey_type_of") || survey_hash.delete(:survey_type_of)
      survey_hash["type_of"] ||= survey_type if survey_type

      polls = survey_hash.delete("polls") || survey_hash.delete(:polls)
      if polls.is_a?(Array)
        survey_hash["polls_attributes"] = polls.map do |poll|
          poll_hash = poll.respond_to?(:to_unsafe_h) ? poll.to_unsafe_h : poll.to_h
          
          poll_type = poll_hash.delete("poll_type_of") || poll_hash.delete(:poll_type_of)
          poll_hash["type_of"] ||= poll_type if poll_type

          options = poll_hash.delete("poll_options") || poll_hash.delete(:poll_options)
          if options.is_a?(Array)
            poll_hash["poll_options_attributes"] = options.map do |opt|
              opt.respond_to?(:to_unsafe_h) ? opt.to_unsafe_h : opt.to_h
            end
          end
          poll_hash
        end
      end

      params[:survey] = ActionController::Parameters.new(survey_hash)
    end
  end
end
