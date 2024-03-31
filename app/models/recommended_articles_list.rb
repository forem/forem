class RecommendedArticlesList < ApplicationRecord
  belongs_to :user
  validates :name, presence: true, length: { maximum: 120 }

  enum placement_area: { main_feed: 0 } # Only main feed for now, could be used in Digest, trending, etc.

  scope :active, -> { where("expires_at > ?", Time.current) }

  before_save :set_default_values

  def set_default_values
    self.expires_at = 1.day.from_now if expires_at.nil?
  end

  # exclude_article_ids is an integer array, web inputs are comma-separated strings
  # ActiveRecord normalizes these in a bad way, so we are intervening
  def article_ids=(input)
    adjusted_input = input.is_a?(String) ? input.split(",") : input
    adjusted_input = adjusted_input&.filter_map { |value| value.presence&.to_i }
    write_attribute :article_ids, (adjusted_input || [])
  end
end
