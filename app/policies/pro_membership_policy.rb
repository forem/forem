class ProMembershipPolicy < ApplicationPolicy
  def create?
    !user.pro?
  end
end
