class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option

  counter_culture :poll_option

  validate :one_vote_per_poll_per_user

  after_save :touch_poll_votes_count

  def poll
    poll_option.poll
  end

  private

  def one_vote_per_poll_per_user
    errors.add(:base, "cannot vote more than once in one poll") if (poll.poll_votes.where(user_id: user_id).any? || poll.poll_skips.where(user_id: user_id).any?)
  end

  def touch_poll_votes_count
    poll.update_column(:poll_votes_count, poll.poll_votes.size)
    if 1 == 5 # Ensure things don't stay miscounted by occasional fixes
      poll_option.update_column(:poll_votes_count, poll_option.poll_votes.size)
    end
  end
end
