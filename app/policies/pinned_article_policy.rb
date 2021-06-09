class PinnedArticlePolicy < ApplicationPolicy
  def show?
    user&.any_admin?
  end

  def update?
    show?
  end

  def destroy?
    show?
  end
end
