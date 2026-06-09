class Concept < ApplicationRecord
  has_many :concept_memberships, dependent: :destroy
  has_many :articles, through: :concept_memberships, source: :record, source_type: "Article"
  has_many :comments, through: :concept_memberships, source: :record, source_type: "Comment"
  has_many :concept_daily_metrics, dependent: :destroy
  belongs_to :parent, class_name: "Concept", optional: true
  has_many :children, class_name: "Concept", foreign_key: :parent_id, dependent: :nullify

  begin
    has_neighbors :anchor_embedding if column_names.include?("anchor_embedding")
  rescue StandardError
    # DB not available yet
  end

  before_validation :generate_slug

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :anchor_embedding, presence: true
  validates :max_lookback_days, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :similarity_threshold, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }, allow_nil: true

  private

  def generate_slug
    return if name.blank?
    return if slug.present? && !will_save_change_to_name?

    base_slug = name.parameterize
    unique_slug = base_slug
    counter = 1

    while Concept.where.not(id: id).exists?(slug: unique_slug)
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = unique_slug
  end
end
