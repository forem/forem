class RssFeed < ApplicationRecord
  belongs_to :user
  belongs_to :fallback_organization, class_name: "Organization", optional: true
  belongs_to :fallback_user, class_name: "User", optional: true

  has_many :rss_feed_imports, dependent: :destroy

  enum status: { active: 0, paused: 1, failed: 2 }

  validates :url, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validate :validate_feed_url, if: :url_changed?

  private

  def validate_feed_url
    return if url.blank?

    valid = Feeds::ValidateUrl.call(url)
    errors.add(:url, I18n.t("models.users.setting.invalid_rss")) unless valid
  rescue StandardError => e
    errors.add(:url, e.message)
  end
end
