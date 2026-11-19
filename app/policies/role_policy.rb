class RolePolicy < ApplicationPolicy
  def remove_role?
    if user.super_admin?
      true
    else
      user.admin? && !record.super_admin? && !record.community_leader_level_2? &&
        !super_admin_only_resource_admin?
    end
  end

  private

  def super_admin_only_resource_admin?
    record.single_resource_admin? &&
      Constants::Role::SUPER_ADMIN_ONLY_RESOURCE_TYPES.include?(record.resource_type)
  end
end
