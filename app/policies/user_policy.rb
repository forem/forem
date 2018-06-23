class UserPolicy < ApplicationPolicy
  def edit?
    user == record
  end

  def onboarding_update?
    true
  end

  def update?
    user == record
  end

  def join_org?
    !user_is_banned?
  end

  def leave_org?
    true
  end

  def add_org_admin?
    user.org_admin && within_the_same_org?
  end

  def remove_org_admin?
    user.org_admin && not_self? && within_the_same_org?
  end

  def remove_from_org?
    user.org_admin && not_self? && within_the_same_org?
  end

  private

  def within_the_same_org?
    user.organization == record.organization
  end

  def not_self?
    user != record
  end
end
