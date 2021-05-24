class PinPolicy < ApplicationPolicy
  def update?
    user.any_admin?
  end

  def destroy?
    update?
  end
end
