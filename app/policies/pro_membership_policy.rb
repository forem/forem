class ProMembershipPolicy < ApplicationPolicy
  def create?
    user.pro_membership.nil? && !user.has_role?(:pro)
  end

  def edit?
    user.pro_membership.present?
  end

  def update?
    edit?
  end
end
