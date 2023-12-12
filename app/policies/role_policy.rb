class RolePolicy < ApplicationPolicy
  def remove_role?
    if user.super_admin?
      true
    else
      user.admin? && !record.super_admin?
    end
  end
end
