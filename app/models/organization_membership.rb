class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  USER_TYPES = %w[admin member guest].freeze

  validates :user_id, :organization_id, :type_of_user, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validates :type_of_user, inclusion: { in: USER_TYPES }

  after_save    :upsert_chat_channel_membership
  after_create  :update_user_organization_info_updated_at
  after_destroy :update_user_organization_info_updated_at

  def update_user_organization_info_updated_at
    user.touch(:organization_info_updated_at)
  end

  private

  def upsert_chat_channel_membership
    # Add to channel or update to mod if user is org admin
  end
end
