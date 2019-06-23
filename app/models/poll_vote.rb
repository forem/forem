class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option
  belongs_to :poll

  counter_culture :poll_option
  counter_culture :poll

  validates :poll_id, presence: true, uniqueness: { scope: :user_id } # In the future we'll remove this constraint if/when we allow multi-answer polls
  validates :poll_option_id, presence: true, uniqueness: { scope: :user_id }
  validate :one_vote_per_poll_per_user

  after_save :touch_poll_votes_count
  after_destroy :touch_poll_votes_count

  delegate :poll, to: :poll_option, allow_nil: true

  private

  def one_vote_per_poll_per_user
    return false unless poll

    has_votes = (
      poll.poll_votes.where(user_id: user_id).any? || poll.poll_skips.where(user_id: user_id).any?)
    errors.add(:base, "cannot vote more than once in one poll") if has_votes
  end

  def touch_poll_votes_count
    poll.update_column(:poll_votes_count, poll.poll_votes.size)
    poll_option.update_column(:poll_votes_count, poll_option.poll_votes.size)
  end
end
