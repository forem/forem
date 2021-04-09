class ListingPolicy < ApplicationPolicy
  def edit?
    user_author? || authorized_organization_admin_editor?
  end

  def update?
    user_author? || authorized_organization_admin_editor?
  end

  def authorized_organization_poster?
    user.org_member?(record.organization_id)
  end

  def delete_confirm?
    update?
  end

  def destroy?
    update?
  end

  private

  def user_author?
    record.user_id == user.id
  end

  def authorized_organization_admin_editor?
    user.org_admin?(record.organization_id)
  end
end
