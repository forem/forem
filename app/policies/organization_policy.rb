class OrganizationPolicy < ApplicationPolicy
  def create?
    !user.banned
  end

  def update?
    user.org_admin?(record)
  end

  def generate_new_secret?
    update?
  end

  def pro_org_user?
    user.has_role?(:pro) && user.org_admin && user.organization_id == record.id
  end
end
