class FollowPolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end
end
