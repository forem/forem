class ProMembershipPolicy < ApplicationPolicy
  def create?
    !(user.pro? || user&.pro_membership&.expired?)
  end
end
