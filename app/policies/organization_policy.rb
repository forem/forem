class OrganizationPolicy < ApplicationPolicy
  def create?
    !user.banned
  end

  def update?
    user.is_org_admin?(record)
  end

  def generate_new_secret?
    update?
  end
end
