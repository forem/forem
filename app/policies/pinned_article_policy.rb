class PinnedArticlePolicy < ApplicationPolicy
  def show?
    user&.any_admin?
  end

  alias update? show?

  alias destroy? show?
end
