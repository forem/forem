module Emails
  class SurveyDailyEmailWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })

    sidekiq_options queue: :low_priority, retry: 5, lock: :until_and_while_executing

    def perform
      Survey.where(active: true).find_each do |survey|
        process_survey(survey)
      end
    end

    private

    def process_survey(survey)
      if survey.target_based?
        # Check if target is already hit or time has passed
        if survey.survey_completions.count >= survey.target_response_count || Time.current >= survey.target_completion_date
          survey.update!(active: false)
          return
        end

        # Adjust send rate if we have been sending for at least 24 hours
        if survey.sending_started_at.present? && Time.current - survey.sending_started_at >= 24.hours
          adjust_send_rate(survey)
        end
      end

      return unless survey.daily_email_distributions.to_i > 0

      send_hourly_emails(survey)
    end

    def adjust_send_rate(survey)
      completions_count = survey.survey_completions.count
      completions_needed = survey.target_response_count - completions_count
      
      days_remaining = (survey.target_completion_date - Time.current).to_f / 1.day
      days_remaining = [days_remaining, 0.01].max

      required_daily_completion_rate = completions_needed.to_f / days_remaining

      conversion_rate = completions_count.to_f / [survey.emails_sent_count, 1].max
      if conversion_rate == 0
        conversion_rate = 0.005 # Assume 1 completion per 200 sends (1/200)
      else
        conversion_rate = [conversion_rate, 0.0001].max
        conversion_rate = [conversion_rate, 1.0].min
      end

      new_daily_send_rate = (required_daily_completion_rate / conversion_rate).round
      new_daily_send_rate = [new_daily_send_rate, 1].max

      survey.update!(daily_email_distributions: new_daily_send_rate)
    end

    def hourly_send_limit(survey)
      hour_of_day = Time.current.hour
      ((hour_of_day + 1) * survey.daily_email_distributions) / 24 - (hour_of_day * survey.daily_email_distributions) / 24
    end

    def send_hourly_emails(survey)
      hourly_to_send = hourly_send_limit(survey)

      return unless hourly_to_send > 0

      eligible_users = User.email_eligible
                           .where("last_presence_at >= ?", 3.months.ago)

      unless survey.allow_resubmission?
        poll_ids = survey.polls.select(:id)
        
        users_with_completions = SurveyCompletion.where(survey: survey).select(:user_id)
        users_with_votes = PollVote.where(poll_id: poll_ids).select(:user_id)
        users_with_skips = PollSkip.where(poll_id: poll_ids).select(:user_id)
        users_with_text_responses = PollTextResponse.where(poll_id: poll_ids).select(:user_id)

        eligible_users = eligible_users.where.not(id: users_with_completions)
                                       .where.not(id: users_with_votes)
                                       .where.not(id: users_with_skips)
                                       .where.not(id: users_with_text_responses)
      end

      sampled_users = eligible_users.order(Arel.sql("RANDOM()"))
                                    .limit(hourly_to_send)

      actual_sent_count = 0
      sampled_users.each do |user|
        SurveyMailer.with(user: user, survey: survey).pulse_survey.deliver_later
        actual_sent_count += 1
      end

      if actual_sent_count > 0
        updates = { emails_sent_count: survey.emails_sent_count + actual_sent_count }
        updates[:sending_started_at] = Time.current if survey.sending_started_at.nil?
        survey.update!(updates)
      end
    end
  end
end
