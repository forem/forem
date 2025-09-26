class SurveyCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :survey

  validates :user_id, uniqueness: { scope: :survey_id }
  validates :completed_at, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :for_surveys, ->(survey_ids) { where(survey_id: survey_ids) }

  # Mark a survey as completed for a user
  def self.mark_completed!(user:, survey:)
    find_or_create_by(user: user, survey: survey) do |completion|
      completion.completed_at = Time.current
    end
  end

  # Check if a user has completed any of the given surveys
  def self.user_completed_any?(user:, survey_ids:)
    return false if user.blank? || survey_ids.blank?

    where(user: user, survey_id: survey_ids).exists?
  end

  # Get all survey IDs that a user has completed
  def self.completed_survey_ids_for_user(user)
    return [] if user.blank?

    where(user: user).pluck(:survey_id)
  end
end
