class PathRedirect < ApplicationRecord
  SOURCES = %w[admin service].freeze

  validates :old_path, presence: true, uniqueness: true
  validates :new_path, presence: true

  # Validate old_path != new_path
  validates :old_path, exclusion: { in: lambda { |path_redirect|
                                          [path_redirect.new_path]
                                        }, message: "the old_path cannot be the same as the new_path" }

  validates :source, inclusion: { in: SOURCES }, allow_blank: true

  # This issues a DB query so best to keep this validation as far down as possible
  validate :new_path_wont_redirect

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

  # This ensures we don't end up in an infinite redirect loop where
  # /old_path --> /new_path and then another record has /new_path --> /old_path
  def new_path_wont_redirect
    return unless PathRedirect.find_by(old_path: new_path)

    errors.add(:new_path, "this new_path is already being redirected")
  end
end
