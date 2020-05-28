class PageRedirect < ApplicationRecord
  SOURCES = %w[admin service].freeze

  validates :old_slug, presence: true, uniqueness: true
  validates :new_slug, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES }

  before_save :increment_version, if: :will_save_change_to_new_slug?

  resourcify

  private

  def increment_version
    self.version += 1
  end
end
