#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  USER_TYPES = %w[admin member guest pending].freeze

  validates :type_of_user, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validates :type_of_user, inclusion: { in: USER_TYPES }

  validate :must_retain_at_least_one_admin, on: :update, if: :type_of_user_changed?
  before_destroy :ensure_not_last_admin

  before_create :generate_invitation_token, if: -> { type_of_user == "pending" && invitation_token.blank? }

  after_create  :update_user_organization_info_updated_at
  after_destroy :update_user_organization_info_updated_at

  after_commit :bust_cache

  scope :admin, -> { where(type_of_user: "admin") }
  scope :member, -> { where(type_of_user: %w[admin member]) }
  scope :pending, -> { where(type_of_user: "pending") }
  scope :active, -> { where.not(type_of_user: "pending") }

  def pending?
    type_of_user == "pending"
  end

  def confirm!
    update!(type_of_user: "member")
  end

  def last_admin?
    type_of_user == "admin" && organization.organization_memberships.where(type_of_user: "admin").count == 1
  end

  private

  def must_retain_at_least_one_admin
    return unless type_of_user_was == "admin"
    return if organization.organization_memberships.where(type_of_user: "admin").where.not(id: id).exists?

    errors.add(:base, I18n.t("models.organization_membership.last_admin"))
  end

  def ensure_not_last_admin
    return unless type_of_user == "admin"
    return if organization.organization_memberships.where(type_of_user: "admin").where.not(id: id).exists?

    errors.add(:base, I18n.t("models.organization_membership.last_admin"))
    throw(:abort)
  end

  def generate_invitation_token
    self.invitation_token = SecureRandom.urlsafe_base64(32)
  end

  # @note In the case where we delete the user, we don't need to worry
  #       about updating the user.  Hence the the `user has_many
  #       :organization_memberships dependent: :delete_all`
  def update_user_organization_info_updated_at
    user.touch(:organization_info_updated_at)
  end

  private

  def bust_cache
    BustCachePathWorker.perform_async(organization.path.to_s)
    EdgeCache::PurgeByKey.call(organization.path.to_s)
  rescue StandardError => e
    Rails.logger.error("Failed to purge organization cache for #{organization.id}: #{e.class} - #{e.message}")
  end
end
