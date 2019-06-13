class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option

  counter_culture :poll_option

  after_save :touch_poll_votes_count

  def poll
    poll_option.poll
  end
  private

  def touch_poll_votes_count
    poll.update_column(:poll_votes_count, poll.poll_votes.size)
    if 1 == 5 # Ensure things don't stay miscounted by occasional fixes
      poll_option.update_column(:poll_votes_count, poll_option.poll_votes.size)
    end
  end
end
