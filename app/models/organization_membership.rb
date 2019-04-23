class OrganizationMembership < ApplicationRecord
  validates :user_id, :organization_id, :type_of_user, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validates :type_of_user, inclusion: { in: %w[admin member guest] }
end
