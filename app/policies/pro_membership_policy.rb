class ProMembershipPolicy < ApplicationPolicy
  def create?
    user.pro_membership.nil? && !user.has_role?(:pro)
  end

  def update?
    user.pro_membership.present?
  end
end
