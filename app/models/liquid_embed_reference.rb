class LiquidEmbedReference < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :referenced, polymorphic: true, optional: true

  validates :tag_name, presence: true
  validates :url, presence: true

  scope :published, -> { where(published: true).where("published_at <= ? OR published_at IS NULL", Time.current) }
  scope :unpublished, -> { where(published: false).or(where("published_at > ?", Time.current)) }
  scope :popular, -> { order(score: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_tag, ->(tag_name) { where(tag_name: tag_name) }
end
