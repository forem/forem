class OrganizationPolicy < ApplicationPolicy
  def create?
    !user.banned
  end

  def update?
    user.org_admin?(record)
  end

  def destroy?
    user.org_admin?(record) && record.destroyable?
  end

  def leave_org?
    part_of_org?
  end

  def part_of_org?
    return false if record.blank?

    OrganizationMembership.exists?(user_id: user.id, organization_id: record.id)
  end

  def admin_of_org?
    return false if record.blank?

    OrganizationMembership.exists?(user_id: user.id, organization_id: record.id, type_of_user: "admin")
  end

  def generate_new_secret?
    update?
  end
end
