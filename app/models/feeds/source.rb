module Feeds
  class Source < ApplicationRecord
    self.table_name = "feed_sources"

    belongs_to :user
    belongs_to :organization, optional: true
    belongs_to :author, class_name: "User", foreign_key: :author_user_id, optional: true, inverse_of: false

    has_many :import_logs, class_name: "Feeds::ImportLog", foreign_key: :feed_source_id,
                           inverse_of: :feed_source, dependent: :nullify

    enum status: { healthy: 0, degraded: 1, failing: 2, inactive: 3 }, _prefix: :feed

    validates :feed_url, presence: true, length: { maximum: 500 }
    validates :feed_url, uniqueness: { scope: :user_id }
    validates :name, length: { maximum: 100 }, allow_nil: true
    validates :referential_link, inclusion: { in: [true, false] }

    validate :validate_feed_url, if: :feed_url_changed?
    validate :validate_organization_membership, if: -> { organization_id.present? && organization_id_changed? }
    validate :validate_author_permission, if: -> { author_user_id.present? && author_user_id_changed? }

    scope :active, -> { where.not(status: :inactive) }

    def effective_author
      author || user
    end

    def update_health!(success:)
      if success
        update!(status: :healthy, status_message: nil, consecutive_failures: 0)
      else
        new_count = consecutive_failures + 1
        new_status = new_count >= 3 ? :failing : :degraded
        update!(status: new_status, consecutive_failures: new_count)
      end
    end

    private

    def validate_feed_url
      return if feed_url.blank?

      valid = Feeds::ValidateUrl.call(feed_url)
      errors.add(:feed_url, "is not a valid RSS feed URL") unless valid
    rescue StandardError => e
      errors.add(:feed_url, e.message)
    end

    def validate_organization_membership
      unless user.organization_memberships.exists?(organization_id: organization_id)
        errors.add(:organization, "you must be a member of this organization")
      end
    end

    def validate_author_permission
      return if author_user_id == user_id

      if organization_id.blank?
        errors.add(:author_user_id, "can only be set when an organization is selected")
        return
      end

      unless user.org_admin?(organization_id)
        errors.add(:author_user_id, "you must be an org admin to assign another author")
        return
      end

      unless OrganizationMembership.exists?(user_id: author_user_id, organization_id: organization_id)
        errors.add(:author_user_id, "must be a member of the selected organization")
      end
    end
  end
end
