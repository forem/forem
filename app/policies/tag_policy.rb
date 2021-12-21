class TagPolicy < ApplicationPolicy
  def index?
    true
  end

  def edit?
    has_mod_permission?
  end

  def update?
    has_mod_permission?
  end

  def admin?
    user_admin?
  end

  private

  def has_mod_permission?
    user_admin? ||
      user.tag_moderator?(tag: record)
  end
end
