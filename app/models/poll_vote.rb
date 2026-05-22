class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option
  belongs_to :poll

  counter_culture :poll_option
  counter_culture :poll

  # For single choice polls, ensure only one vote per user per poll per session (for survey polls)
  # For multiple choice and scale polls, allow multiple votes but ensure uniqueness per option per session (for survey polls)
  # For regular polls (non-survey), use the old behavior
  validates :poll_id, uniqueness: { scope: %i[user_id session_start] }, if: :single_choice_survey_poll?
  validates :poll_option_id, uniqueness: { scope: %i[user_id session_start] }, if: :survey_poll?

  validates :poll_id, uniqueness: { scope: :user_id }, if: :single_choice_regular_poll?
  validates :poll_option_id, uniqueness: { scope: :user_id }, if: :regular_poll?

  private

  def single_choice_poll?
    poll&.single_choice?
  end

  def survey_poll?
    poll&.survey.present?
  end

  def regular_poll?
    !survey_poll?
  end

  def single_choice_survey_poll?
    single_choice_poll? && survey_poll?
  end

  def single_choice_regular_poll?
    single_choice_poll? && regular_poll?
  end
end
