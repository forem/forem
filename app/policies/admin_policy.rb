class AdminPolicy < ApplicationPolicy
  def show?
    user_is_admin?
  end
end
