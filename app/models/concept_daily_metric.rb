class ConceptDailyMetric < ApplicationRecord
  belongs_to :concept

  validates :concept_id, uniqueness: { scope: :date }
  validates :date, presence: true
  validates :articles_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :page_views, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :reactions_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :comments_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :popularity_score, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
end
