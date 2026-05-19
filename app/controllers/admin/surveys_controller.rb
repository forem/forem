module Admin
  class SurveysController < Admin::ApplicationController
    layout "admin"

    def index
      @surveys = Survey.order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @survey = Survey.includes(polls: :poll_options).find(params[:id])

      @start_date = params[:start_date].presence ? Time.zone.parse(params[:start_date]).beginning_of_day : @survey.created_at.beginning_of_day
      @end_date = params[:end_date].presence ? Time.zone.parse(params[:end_date]).end_of_day : Time.current.end_of_day

      polls = @survey.polls
      poll_ids_relation = polls.select(:id)

      completions = @survey.survey_completions.where(completed_at: @start_date..@end_date)

      @survey_stats = {
        polls_count: polls.size,
        completions_count: completions.count,
        unique_respondents_count: completions.select(:user_id).distinct.count,
        poll_votes_count: PollVote.where(poll_id: poll_ids_relation, created_at: @start_date..@end_date).count,
        poll_skips_count: PollSkip.where(poll_id: poll_ids_relation, created_at: @start_date..@end_date).count,
        poll_text_responses_count: PollTextResponse.where(poll_id: poll_ids_relation, created_at: @start_date..@end_date).count,
        last_completed_at: completions.maximum(:completed_at)
      }

      @poll_data = polls.map do |poll|
        data = {
          poll: poll,
          skips: poll.poll_skips.where(created_at: @start_date..@end_date).count
        }

        if poll.text_input?
          text_responses = poll.poll_text_responses.where(created_at: @start_date..@end_date).order(created_at: :desc).limit(100)
          data[:total_responses] = poll.poll_text_responses.where(created_at: @start_date..@end_date).count
          data[:text_responses] = text_responses.pluck(:text_response, :created_at)
        else
          votes = poll.poll_votes.where(created_at: @start_date..@end_date).group(:poll_option_id).count
          data[:total_responses] = votes.values.sum
          data[:options] = poll.poll_options.map do |opt|
            {
              id: opt.id,
              markdown: opt.markdown,
              votes: votes[opt.id] || 0
            }
          end
        end

        data
      end
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
        :title, :type_of, :active, :display_title, :allow_resubmission, :daily_email_distributions, :extra_email_context_paragraph,
        polls_attributes: [
          :id, :prompt_markdown, :type_of, :position, :scale_min, :scale_max, :_destroy,
          poll_options_attributes: %i[id markdown supplementary_text position _destroy]
        ]
      )
    end
  end
end
