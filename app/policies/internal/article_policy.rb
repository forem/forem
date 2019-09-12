class Internal::ArticlePolicy < ApplicationPolicy
  def index?
    intern_admin?
  end

  def show?
    intern_admin?
  end

  def update?
    intern_admin?
  end
end
