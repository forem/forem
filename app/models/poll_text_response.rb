class PollTextResponse < ApplicationRecord
  belongs_to :poll
  belongs_to :user

  validates :text_content, presence: true, length: { maximum: 1000 }
  validates :poll_id, uniqueness: { scope: :user_id }
end
