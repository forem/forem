module ChatChannelMembershipsHelper
  def formatted_membership_user(memberships)
    memberships.map do |membership|
      {
        name: membership.user.name,
        username: membership.user.username,
        user_id: membership.user.id,
        membership_id: membership.id,
        role: membership.role,
        status: membership.status,
        image: ProfileImage.new(membership.user).get(width: 90),
        chat_channel_name: membership.chat_channel.channel_name,
        chat_channel_id: membership.chat_channel.id,
        slug: membership.chat_channel.slug
      }
    end
  end
end
