class ProMembershipPolicy < ApplicationPolicy
  def create?
    !(user.pro_membership&.expired? || user.pro?)
  end

  def update?
    user.pro?
  end
end
