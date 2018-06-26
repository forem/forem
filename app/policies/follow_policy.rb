class FollowPolicy < ApplicationPolicy
  def create?
    !user.banned
  end
end
