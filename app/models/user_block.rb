class UserBlock < ApplicationRecord
  belongs_to :blocker, foreign_key: "blocker_id", class_name: "User", inverse_of: :blocker_blocks
  belongs_to :blocked, foreign_key: "blocked_id", class_name: "User", inverse_of: :blocked_blocks

  validates :blocked_id, :blocker_id, :config, presence: true
  validates :blocked_id, uniqueness: { scope: %i[blocker_id] }
  validates :config, inclusion: { in: %w[default] }
  validate :blocker_cannot_be_same_as_blocked

  counter_culture :blocker, column_name: "blocking_others_count"
  counter_culture :blocked, column_name: "blocked_by_count"

  class << self
    def blocking?(blocker_id, blocked_id)
      exists?(blocker_id: blocker_id, blocked_id: blocked_id)
    end
  end

  private

  def blocker_cannot_be_same_as_blocked
    errors.add(:blocker_id, "can't be the same as the blocked_id") if blocker_id == blocked_id
  end
end
