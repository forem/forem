class Internal::ArticlePolicy < ApplicationPolicy
  def index?
    article_admin?
  end

  def show?
    article_admin?
  end

  def update?
    article_admin?
  end

  private

  def article_admin?
    user.has_role?(:single_resource_admin, Article) || user.has_role?(:super_admin) || user.has_role?(:admin)
  end
end
