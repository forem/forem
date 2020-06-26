class ReviewItem < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  belongs_to :reviewer, class_name: "User", inverse_of: :review_items, optional: true
  belongs_to :reviewable, polymorphic: true
  validates :reviewable_id, presence: true
  validates :reviewable_type, presence: true, inclusion: { in: ALLOWED_TYPES }

  scope :reviewable_articles, ->(reviewer_id) { where("reviewed = false AND reviewable_type = 'Article' AND (reviewer_id IS NULL OR reviewer_id = ?)", reviewer_id) }
end
