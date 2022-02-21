class ListingPolicy < ApplicationPolicy
  def edit?
    user_author? || authorized_organization_admin_editor?
  end

  alias update? edit?

  def authorized_organization_poster?
    user.org_member?(record.organization_id)
  end

  alias delete_confirm? edit?

  alias destroy? edit?

  private

  def user_author?
    record.user_id == user.id
  end

  def authorized_organization_admin_editor?
    user.org_admin?(record.organization_id)
  end
end
