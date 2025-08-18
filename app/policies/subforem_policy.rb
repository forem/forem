class SubforemPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    has_mod_permission?
  end

  def edit?
    has_mod_permission?
  end

  alias update? edit?

  def admin?
    user_super_admin?
  end

  private

  def has_mod_permission?
    user_super_admin? ||
      user.super_moderator? ||
      user.subforem_moderator?(subforem: record)
  end
end
