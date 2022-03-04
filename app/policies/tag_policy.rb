class TagPolicy < ApplicationPolicy
  def index?
    true
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
      user.tag_moderator?(tag: record)
  end
end
