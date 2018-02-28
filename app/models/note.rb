class Note < ApplicationRecord
  belongs_to :user
  validates :user_id, :reason, :content, presence: true
  validates :user_id, uniqueness:
    { scope: :reason, message: "limited to one note per user per reason" }
end
