# A removed membership needs an explicit invitation before it can return.
# Keep this separate from the membership, which existing removal flows delete.
class OrganizationMembershipExclusion < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  validates :user_id, uniqueness: { scope: :organization_id }
end
