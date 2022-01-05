#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
#
# @note When we destroy the related poll, it's using dependent:
#       :delete for the relationship.  That means no before/after
#       destroy callbacks will be called on this object.
class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option
  belongs_to :poll

  counter_culture :poll_option
  counter_culture :poll

  # In the future we'll remove this constraint if/when we allow multi-answer polls
  validates :poll_id, presence: true, uniqueness: { scope: :user_id }

  validates :poll_option_id, presence: true, uniqueness: { scope: :user_id }
  validate :one_vote_per_poll_per_user

  after_destroy :touch_poll_votes_count
  after_save :touch_poll_votes_count

  delegate :poll, to: :poll_option, allow_nil: true

  private

  def one_vote_per_poll_per_user
    return false unless poll
    return false unless poll.vote_previously_recorded_for?(user_id: user_id)

    errors.add(:base, "cannot vote more than once in one poll")
  end

  def touch_poll_votes_count
    poll.update_column(:poll_votes_count, poll.poll_votes.size)
    poll_option.update_column(:poll_votes_count, poll_option.poll_votes.size)
  end
end
