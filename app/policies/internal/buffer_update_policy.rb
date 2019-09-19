class Internal::BufferUpdatePolicy < ApplicationPolicy
  def create?
    return true
    article_admin?
  end

  def update?
    return true
    article_admin?
  end
end
