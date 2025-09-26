class SurveyCompletionService
  def self.check_and_mark_completion(user:, poll:)
    return unless poll.survey.present?
    return unless user.present?

    survey = poll.survey

    # Check if the survey is now completed by the user
    return unless survey.completed_by_user?(user)

    # Mark the survey as completed if it hasn't been marked already
    survey.mark_completed_by_user!(user) unless survey.completion_recorded_for_user?(user)
  end
end
