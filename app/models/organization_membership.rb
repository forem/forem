#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  USER_TYPES = %w[admin member guest].freeze

  validates :user_id, :organization_id, :type_of_user, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validates :type_of_user, inclusion: { in: USER_TYPES }

  after_create  :update_user_organization_info_updated_at
  after_destroy :update_user_organization_info_updated_at

  # @note In the case where we delete the user, we don't need to worry
  #       about updating the user.  Hence the the `user has_many
  #       :organization_memberships dependent: :delete_all`
  def update_user_organization_info_updated_at
    user.touch(:organization_info_updated_at)
  end
end
