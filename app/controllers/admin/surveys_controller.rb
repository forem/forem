module Admin
  class SurveysController < Admin::ApplicationController
    layout "admin"

    def index
      @surveys = Survey.order(created_at: :desc).page(params[:page]).per(25)
      survey_ids = @surveys.map(&:id)
      @polls_counts = survey_ids.any? ? Poll.where(survey_id: survey_ids).group(:survey_id).count : {}
    end

    def show
      @survey = Survey.includes(polls: :poll_options).find(params[:id])
      @start_date = parse_date_param(params[:start_date])&.beginning_of_day || @survey.created_at.beginning_of_day
      @end_date = parse_date_param(params[:end_date])&.end_of_day || Time.current.end_of_day
      date_range = @start_date..@end_date

      polls = @survey.polls
      poll_ids = polls.map(&:id)

      completions_count, unique_respondents_count, last_completed_at =
        @survey.survey_completions.where(completed_at: date_range).pick(
          Arel.sql("COUNT(*)"), Arel.sql("COUNT(DISTINCT user_id)"), Arel.sql("MAX(completed_at)")
        )
      poll_skips_counts, poll_text_response_counts, poll_vote_counts = load_poll_counts(poll_ids, date_range)

      @survey_stats = {
        polls_count: polls.size,
        completions_count: completions_count.to_i,
        unique_respondents_count: unique_respondents_count.to_i,
        poll_votes_count: poll_vote_counts.values.sum,
        poll_skips_count: poll_skips_counts.values.sum,
        poll_text_responses_count: poll_text_response_counts.values.sum,
        last_completed_at: last_completed_at&.in_time_zone
      }

      @poll_data = build_poll_data(polls, date_range, poll_skips_counts, poll_text_response_counts, poll_vote_counts)
    end

    def new
      @survey = Survey.new
      @survey.polls.build
    end

    def edit
      @survey = Survey.includes(polls: :poll_options).find(params[:id])
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

    def parse_date_param(value)
      Time.zone.parse(value) if value.present?
    rescue ArgumentError, TypeError
      nil
    end

    def load_poll_counts(poll_ids, date_range)
      return [{}, {}, {}] if poll_ids.empty?

      [
        PollSkip.where(poll_id: poll_ids, created_at: date_range).group(:poll_id).count,
        PollTextResponse.where(poll_id: poll_ids, created_at: date_range).group(:poll_id).count,
        PollVote.where(poll_id: poll_ids, created_at: date_range).group(:poll_id, :poll_option_id).count,
      ]
    end

    def build_poll_data(polls, date_range, poll_skips_counts, poll_text_response_counts, poll_vote_counts)
      poll_votes_by_poll = poll_vote_counts.each_with_object(Hash.new(0)) do |((poll_id, _), count), totals|
        totals[poll_id] += count
      end

      polls.map do |poll|
        data = { poll: poll, skips: poll_skips_counts[poll.id] || 0 }

        if poll.text_input?
          total_responses = poll_text_response_counts[poll.id] || 0
          data[:total_responses] = total_responses
          data[:text_responses] = if total_responses.positive?
                                    poll.poll_text_responses.where(created_at: date_range)
                                      .order(created_at: :desc).limit(100)
                                      .pluck(:text_content, :created_at)
                                  else
                                    []
                                  end
        else
          data[:total_responses] = poll_votes_by_poll[poll.id]
          data[:options] = poll.poll_options.map do |opt|
            { id: opt.id, markdown: opt.markdown, votes: poll_vote_counts[[poll.id, opt.id]] || 0 }
          end
        end

        data
      end
    end

    def survey_params
      params.require(:survey).permit(
        :title, :type_of, :active, :display_title, :allow_resubmission,
        :daily_email_distributions, :extra_email_context_paragraph,
        :target_response_count, :target_completion_date,
        polls_attributes: [
          :id, :prompt_markdown, :type_of, :position, :scale_min, :scale_max, :_destroy,
          { poll_options_attributes: %i[id markdown supplementary_text position _destroy] }
        ]
      )
    end
  end
end
