class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option
  belongs_to :poll

  counter_culture :poll_option
  counter_culture :poll

  # For single choice polls, ensure only one vote per user per poll
  # For multiple choice and scale polls, allow multiple votes but ensure uniqueness per option
  validates :poll_id, uniqueness: { scope: :user_id }, if: :single_choice_poll?
  validates :poll_option_id, uniqueness: { scope: :user_id }

  after_destroy :touch_poll_votes_count
  after_save :touch_poll_votes_count

  delegate :poll, to: :poll_option, allow_nil: true

  private

  def single_choice_poll?
    poll&.single_choice?
  end

  def touch_poll_votes_count
    poll.update_column(:poll_votes_count, poll.poll_votes.size)
    poll_option.update_column(:poll_votes_count, poll_option.poll_votes.size)
  end
end