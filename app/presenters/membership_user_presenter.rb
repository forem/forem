class MembershipUserPresenter
  def initialize(membership)
    @membership = membership
  end

  attr_accessor :membership

  def as_json
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
