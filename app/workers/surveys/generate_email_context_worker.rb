module Surveys
  class GenerateEmailContextWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3

    def perform(survey_id)
      survey = Survey.find_by(id: survey_id)
      return unless survey
      return unless survey.extra_email_context_paragraph.blank?
      return if survey.title.blank?
      return if survey.polls.reject(&:marked_for_destruction?).empty?

      generated_context = Ai::SurveyContextGenerator.new(survey).call
      if generated_context.present?
        survey.update_columns(extra_email_context_paragraph: generated_context)
      end
    end
  end
end
