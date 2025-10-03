class SubforemPolicy < ApplicationPolicy
  def index?
    user_super_admin? || user.roles.exists?(name: "subforem_moderator")
  end

  def show?
    has_mod_permission?
  end

  def edit?
    has_mod_permission? || user_super_moderator?
  end

  alias update? edit?

  def add_tag?
    has_mod_permission? || user_super_moderator?
  end

  def admin?
    user_super_admin?
  end

  private

  def has_mod_permission?
    user_super_admin? ||
      user.subforem_moderator?(subforem: record)
  end
end
