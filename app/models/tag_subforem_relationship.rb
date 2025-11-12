class TagSubforemRelationship < ApplicationRecord
  belongs_to :tag
  belongs_to :subforem

  validates :tag_id, presence: true, uniqueness: { scope: :subforem_id }
  validates :subforem_id, presence: true, uniqueness: { scope: :tag_id }

  # Fallback methods to use relationship-specific data if present, otherwise fall back to tag data
  def display_short_summary
    short_summary.presence || tag.short_summary
  end

  def display_pretty_name
    pretty_name.presence || tag.pretty_name
  end

  def display_bg_color_hex
    bg_color_hex.presence || tag.bg_color_hex
  end

  def display_text_color_hex
    text_color_hex.presence || tag.text_color_hex
  end
end
