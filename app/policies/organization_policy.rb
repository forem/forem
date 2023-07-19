class OrganizationPolicy < ApplicationPolicy
  def create?
    !user.suspended?
  end

  def update?
    user.org_admin?(record)
  end

  def destroy?
    user.super_admin? || (user.org_admin?(record) && record.destroyable?)
  end

  def leave_org?
    part_of_org?
  end

  def part_of_org?
    return false if record.blank?

    user.org_member?(record)
  end

  def admin_of_org?
    return false if record.blank?

    user.org_admin?(record)
  end

  alias generate_new_secret? update?

  # The analytics? policy method is also on the UserPolicy.  This exists specifically to allow for
  # "duck-typing" on the tests.
  alias analytics? part_of_org?
end
