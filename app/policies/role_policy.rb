class RolePolicy < ApplicationPolicy
  def remove_role?
    return false if record.suspended?

    if user.super_admin?
      true
    else
      user.admin? && !record.super_admin?
    end
  end
end
