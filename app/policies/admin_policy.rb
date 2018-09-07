class AdminPolicy < ApplicationPolicy
  def show?
    user_admin?
  end
end
