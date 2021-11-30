#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
#
# @note When we destroy the related poll, it's using dependent:
#       :delete for the relationship.  That means no before/after
#       destroy callbacks will be called on this object.
class PollSkip < ApplicationRecord
  belongs_to :poll
  belongs_to :user

  validate :one_vote_per_poll_per_user

  private

  def one_vote_per_poll_per_user
    return false unless poll
    return false unless poll.vote_previously_recorded_for?(user_id: user_id)

    errors.add(:base, "cannot vote more than once in one poll")
  end
end
