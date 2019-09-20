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
end
