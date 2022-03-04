class AdminPolicy < ApplicationPolicy
  def show?
    user_super_admin?
  end

  def minimal?
    user_any_admin?
  end
end
