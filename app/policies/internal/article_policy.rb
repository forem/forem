class Internal::ArticlePolicy < ApplicationPolicy
  def index?
    scoped_admin?
  end

  def show?
    scoped_admin?
  end

  def update?
    scoped_admin?
  end
end
