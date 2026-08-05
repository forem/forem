class FlagAppeal < ApplicationRecord
  belongs_to :user
  belongs_to :appealable, polymorphic: true
  belongs_to :resolved_by, class_name: "User", optional: true

  enum :status, { open: 0, ai_reviewed: 1, approved: 2, rejected: 3 }
  enum :ai_recommendation, { auto_unflag: 0, human_review: 1, confirm_flag: 2 }

  validates :reason, presence: true, length: { maximum: 3000 }
  validates :status, :ai_recommendation, presence: true
  validate :must_not_have_pending_appeal, on: :create

  scope :pending_review, -> { where(status: %i[open ai_reviewed]) }
  scope :recent_first, -> { order(created_at: :desc) }

  def pending_review?
    open? || ai_reviewed?
  end

  private

  def must_not_have_pending_appeal
    return unless user_id && appealable_id && appealable_type

    pending_exists = self.class.where(
      user_id: user_id,
      appealable_type: appealable_type,
      appealable_id: appealable_id,
    ).pending_review.exists?

    return unless pending_exists

    errors.add(:base, "You already have an open appeal pending review for this item.")
  end
end
