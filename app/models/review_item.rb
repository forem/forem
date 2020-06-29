class ReviewItem < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  belongs_to :reviewer, class_name: "User", inverse_of: :review_items, optional: true
  belongs_to :reviewable, polymorphic: true
  validates :reviewable_id, presence: true
  validates :reviewable_type, presence: true, inclusion: { in: ALLOWED_TYPES }

  scope :reviewable_articles, ->(reviewer_id) { where("reviewed = false AND reviewable_type = 'Article' AND (reviewer_id IS NULL OR reviewer_id = ?)", reviewer_id) }

  class << self
    def mark_as_reviewed(reviewable, reviewer)
      review_item = find_or_initialize_by(reviewable: reviewable, reviewer: reviewer)
      return if review_item.reviewed

      review_item.reviewed = true
      review_item.read = true
      review_item.save!
    end
  end
end
