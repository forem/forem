class AdminPolicy < ApplicationPolicy
  def show?
    user_admin?
  end

  def minimal?
    minimal_admin?
  end
end
