class UserBlock < ApplicationRecord
  belongs_to :blocker, class_name: "User", inverse_of: :blocker_blocks
  belongs_to :blocked, class_name: "User", inverse_of: :blocked_blocks

  validates :blocked_id, :blocker_id, :config, presence: true
  validates :blocked_id, uniqueness: { scope: %i[blocker_id] }
  validates :config, inclusion: { in: %w[default] }
  validate :blocker_cannot_be_same_as_blocked

  counter_culture :blocker, column_name: "blocking_others_count"
  counter_culture :blocked, column_name: "blocked_by_count"

  after_create :bust_blocker_cache
  before_destroy :bust_blocker_cache

  BLOCKED_IDS_CACHE_KEY = "blocked_ids_for_blocker/".freeze

  class << self
    def blocking?(blocker_id, blocked_id)
      exists?(blocker_id: blocker_id, blocked_id: blocked_id)
    end

    def cached_blocked_ids_for_blocker(blocker_id)
      Rails.cache.fetch("#{BLOCKED_IDS_CACHE_KEY}#{blocker_id}", expires_in: 48.hours) do
        where(blocker_id: blocker_id).pluck(:blocked_id)
      end
    end
  end

  private

  def blocker_cannot_be_same_as_blocked
    errors.add(:blocker_id, "can't be the same as the blocked_id") if blocker_id == blocked_id
  end

  def bust_blocker_cache
    Rails.cache.delete("#{BLOCKED_IDS_CACHE_KEY}#{blocker_id}")
  end
end
