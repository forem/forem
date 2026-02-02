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

  alias remove_tag? add_tag?

  def create_navigation_link?
    has_mod_permission? || user_super_moderator?
  end

  def update_navigation_link?
    has_mod_permission? || user_super_moderator?
  end

  def destroy_navigation_link?
    has_mod_permission? || user_super_moderator?
  end

  def create_page?
    has_mod_permission? || user_super_moderator?
  end

  def update_page?
    has_mod_permission? || user_super_moderator?
  end

  def destroy_page?
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
