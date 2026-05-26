module Admin
  class SurveysController < Admin::ApplicationController
    layout "admin"

    def index
      @surveys = Survey.order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @survey = Survey.includes(polls: :poll_options).find(params[:id])

      parsed_start = params[:start_date].presence ? (Time.zone.parse(params[:start_date]) rescue nil) : nil
      @start_date = parsed_start ? parsed_start.beginning_of_day : @survey.created_at.beginning_of_day

      parsed_end = params[:end_date].presence ? (Time.zone.parse(params[:end_date]) rescue nil) : nil
      @end_date = parsed_end ? parsed_end.end_of_day : Time.current.end_of_day

      polls = @survey.polls
      poll_ids = polls.map(&:id)

      completions = @survey.survey_completions.where(completed_at: @start_date..@end_date)

      @survey_stats = {
        polls_count: polls.size,
        completions_count: completions.count,
        unique_respondents_count: completions.select(:user_id).distinct.count,
        poll_votes_count: PollVote.where(poll_id: poll_ids, created_at: @start_date..@end_date).count,
        poll_skips_count: PollSkip.where(poll_id: poll_ids, created_at: @start_date..@end_date).count,
        poll_text_responses_count: PollTextResponse.where(poll_id: poll_ids, created_at: @start_date..@end_date).count,
        last_completed_at: completions.maximum(:completed_at)
      }

      # Pre-calculate counts grouped by poll and option to avoid N+1
      poll_skips_counts = PollSkip.where(poll_id: poll_ids, created_at: @start_date..@end_date).group(:poll_id).count
      poll_text_response_counts = PollTextResponse.where(poll_id: poll_ids, created_at: @start_date..@end_date).group(:poll_id).count
      poll_vote_counts = PollVote.where(poll_id: poll_ids, created_at: @start_date..@end_date).group(:poll_id, :poll_option_id).count

      @poll_data = polls.map do |poll|
        data = {
          poll: poll,
          skips: poll_skips_counts[poll.id] || 0
        }

        if poll.text_input?
          text_responses = poll.poll_text_responses.where(created_at: @start_date..@end_date).order(created_at: :desc).limit(100)
          data[:total_responses] = poll_text_response_counts[poll.id] || 0
          data[:text_responses] = text_responses.pluck(:text_content, :created_at)
        else
          poll_votes_subset = poll_vote_counts.select { |(p_id, _), _| p_id == poll.id }
          data[:total_responses] = poll_votes_subset.values.sum
          data[:options] = poll.poll_options.map do |opt|
            {
              id: opt.id,
              markdown: opt.markdown,
              votes: poll_vote_counts[[poll.id, opt.id]] || 0
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
