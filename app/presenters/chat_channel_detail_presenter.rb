class ChatChannelDetailPresenter
  def initialize(chat_channel, current_membership)
    @chat_channel = chat_channel
    @current_membership = current_membership
  end

  attr_accessor :chat_channel, :current_membership

  def as_json
    {
      chat_channel: {
        name: chat_channel.channel_name,
        type: chat_channel.channel_type,
        description: chat_channel.description,
        discoverable: chat_channel.discoverable,
        slug: chat_channel.slug,
        status: chat_channel.status,
        id: chat_channel.id
      },
      memberships: {
        active: membership_users(chat_channel.active_memberships),
        pending: membership_users(chat_channel.pending_memberships),
        requested: membership_users(chat_channel.requested_memberships)
      },
      current_membership: current_membership
    }
  end

  def membership_users(memberships)
    memberships.includes(:user).map do |membership|
      {
        name: membership.user.name,
        username: membership.user.username,
        user_id: membership.user.id,
        membership_id: membership.id,
        role: membership.role,
        status: membership.status,
        image: ProfileImage.new(membership.user).get(width: 90)
      }
    end
  end
end
