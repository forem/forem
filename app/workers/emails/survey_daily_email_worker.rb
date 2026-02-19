module Emails
  class SurveyDailyEmailWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })

    sidekiq_options queue: :low_priority, retry: 5, lock: :until_and_while_executing

    def perform
      Survey.where(active: true).where("daily_email_distributions > 0").find_each do |survey|
        send_daily_emails(survey)
      end
    end

    private

    def send_daily_emails(survey)
      return unless survey.daily_email_distributions.to_i > 0

      eligible_users = User.email_eligible
                           .where("last_presence_at >= ?", 3.months.ago)

      # Determine if we should filter out users who have completed this survey
      unless survey.allow_resubmission?
        # A user has completed the survey if they have a survey_completion record
        # OR if they have voted/skipped/responded to all polls in their latest session.
        # Since 'completed_by_user?' is a Ruby method with complex session logic, the simplest fully accurate DB approach
        # is to filter out anyone who has a SurveyCompletion OR has at least one poll interaction 
        # (meaning they've started or finished it before). If we want to strictly reach only people who 
        # haven't interacted with it at all yet, we exclude those with any poll votes/skips/text responses for this survey.
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

      # Randomly sample the desired number of users via DB
      sampled_users = eligible_users.order(Arel.sql("RANDOM()"))
                                    .limit(survey.daily_email_distributions)

      sampled_users.each do |user|
        SurveyMailer.with(user: user, survey: survey).pulse_survey.deliver_later
      end
    end
  end
end
