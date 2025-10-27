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

  validate :one_vote_per_poll_per_user_per_session

  private

  def one_vote_per_poll_per_user_per_session
    return false unless poll
    return false unless poll.vote_previously_recorded_for_in_session?(user_id: user_id, session_start: session_start)

    errors.add(:base, I18n.t("models.poll_skip.cannot_vote_more_than_once"))
  end
end
