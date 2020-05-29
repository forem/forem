class PageRedirect < ApplicationRecord
  SOURCES = %w[admin service].freeze

  validates :old_path, presence: true, uniqueness: true
  validates :new_path, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES }

  before_save :increment_version, if: :will_save_change_to_new_path?

  resourcify

  def old_path_url
    URL.url(old_path)
  end

  def new_path_url
    URL.url(new_path)
  end

  private

  def increment_version
    self.version += 1
  end
end
