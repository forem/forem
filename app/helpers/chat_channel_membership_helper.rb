module ChatChannelMembershipHelper
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

  def format_membership(membership)
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
