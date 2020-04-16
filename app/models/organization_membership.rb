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
    return if type_of_user == "guest"

    role = type_of_user == "admin" ? "mod" : "member"
    name = "@#{organization.slug} private group chat"
    channel = ChatChannel.find_by(channel_name: name)
    if channel
      add_chat_channel_membership(user, channel, role)
    else
      ChatChannel.create_with_users(
        users: [user],
        channel_type: "invite_only",
        contrived_name: name,
        membership_role: role,
      )
    end
  end

  def add_chat_channel_membership(user, channel, role)
    membership = ChatChannelMembership.find_or_initialize_by(user_id: user.id, chat_channel_id: channel.id)
    membership.role = role
    membership.save
  end
end
