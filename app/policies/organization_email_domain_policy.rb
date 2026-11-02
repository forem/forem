class OrganizationEmailDomainPolicy < ApplicationPolicy
  def review?
    user.super_admin?
  end
end
