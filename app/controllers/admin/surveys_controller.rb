module Admin
  class SurveysController < Admin::ApplicationController
    layout "admin"

    def index
      @surveys = Survey.order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @survey = Survey.includes(polls: :poll_options).find(params[:id])

      polls = @survey.polls
      poll_ids_relation = polls.select(:id)

      @survey_stats = {
        polls_count: polls.size,
        completions_count: @survey.survey_completions.count,
        unique_respondents_count: @survey.survey_completions.select(:user_id).distinct.count,
        poll_votes_count: polls.sum(:poll_votes_count),
        poll_skips_count: polls.sum(:poll_skips_count),
        poll_text_responses_count: PollTextResponse.where(poll_id: poll_ids_relation).count,
        last_completed_at: @survey.survey_completions.maximum(:completed_at)
      }
    end

    def new
      @survey = Survey.new
      @survey.polls.build
    end

    def edit
      @survey = Survey.find(params[:id])
    end

    def create
      @survey = Survey.new(survey_params)

      if @survey.save
        flash[:success] = I18n.t("admin.surveys_controller.created")
        redirect_to admin_surveys_path
      else
        flash.now[:danger] = @survey.errors_as_sentence
        render :new
      end
    end

    def update
      @survey = Survey.find(params[:id])

      if @survey.update(survey_params)
        flash[:success] = I18n.t("admin.surveys_controller.updated")
        redirect_to admin_surveys_path
      else
        flash.now[:danger] = @survey.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @survey = Survey.find(params[:id])

      if @survey.destroy
        flash[:success] = I18n.t("admin.surveys_controller.deleted")
      else
        flash[:danger] = @survey.errors_as_sentence
      end
      redirect_to admin_surveys_path
    end

    private

    def survey_params
      params.require(:survey).permit(
        :title, :active, :display_title, :allow_resubmission,
        polls_attributes: [
          :id, :prompt_markdown, :type_of, :position, :scale_min, :scale_max, :_destroy,
          poll_options_attributes: %i[id markdown supplementary_text position _destroy]
        ]
      )
    end
  end
end
