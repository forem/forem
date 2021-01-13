class StripeActiveCardPolicy < ApplicationPolicy
  def create?
    !user_is_suspended?
  end

  def update?
    !user_is_suspended?
  end

  def destroy?
    true
  end
end
