class SortableCount < ApplicationRecord
  belongs_to :countable, polymorphic: true

  validates :slug, uniqueness: { scope: %i[countable_id countable_type] }

  before_save :apply_title_if_none

  private

  def apply_title_if_none
    self.title = slug.titleize if title.blank?
  end
end
