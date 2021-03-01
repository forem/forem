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
        image: Images::Profile.call(membership.user.profile_image_url, length: 90),
        chat_channel_name: membership.chat_channel.channel_name,
        chat_channel_id: membership.chat_channel.id,
        slug: membership.chat_channel.slug
      }
    end
  end

  def membership_users(memberships)
    memberships.includes(:user).map do |membership|
      format_membership(membership)
    end
  end

  def format_membership(membership)
    {
      name: membership.user.name,
      username: membership.user.username,
      user_id: membership.user.id,
      membership_id: membership.id,
      role: membership.role,
      status: membership.status,
      image: Images::Profile.call(membership.user.profile_image_url, length: 90)
    }
  end
end
