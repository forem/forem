class RssFeed < ApplicationRecord
  belongs_to :user
  belongs_to :fallback_organization, class_name: "Organization", optional: true
  belongs_to :fallback_author, class_name: "User", optional: true
  has_many :rss_feed_items, dependent: :destroy
  has_many :articles, dependent: :nullify

  enum status: { active: 0, paused: 1, error: 2 }

  validates :feed_url, presence: true, length: { maximum: 500 },
                       uniqueness: { scope: :user_id }
  validates :name, length: { maximum: 100 }, allow_nil: true

  validate :validate_feed_url, if: :feed_url_changed?
  validate :validate_fallback_organization

  scope :fetchable, -> { where(status: :active) }

  private

  def validate_feed_url
    return if feed_url.blank?

    valid = Feeds::ValidateUrl.call(feed_url)
    errors.add(:feed_url, I18n.t("models.rss_feed.invalid_rss")) unless valid
  rescue StandardError => e
    errors.add(:feed_url, e.message)
  end

  def validate_fallback_organization
    return if fallback_organization_id.blank?

    return if user.org_admin?(fallback_organization)

    errors.add(:fallback_organization, I18n.t("models.rss_feed.not_org_admin"))
  end
end
