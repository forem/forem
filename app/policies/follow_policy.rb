class FollowPolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  def update?
    user_is_follower?
  end

  def permitted_attributes
    %i[points]
  end

  private

  def user_is_follower?
    record.follower_id == user.id && record.follower_type == "User"
  end
end
