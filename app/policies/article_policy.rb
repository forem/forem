class ArticlePolicy < ApplicationPolicy
  def update?
    user_is_author? || user_is_admin? || user_is_org_admin?
  end

  def new?
    !user_is_banned?
  end

  def create?
    !user_is_banned?
  end

  private

  def user_is_author?
    record.user_id == user.id
  end

  def user_is_org_admin?
    user.org_admin && user.organization_id == record.organization_id
  end

  def user_is_banned?
    user && user.has_role?(:banned)
  end
end
