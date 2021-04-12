class StripeActiveCardPolicy < ApplicationPolicy
  def create?
    !user_suspended?
  end

  def update?
    !user_suspended?
  end

  def destroy?
    true
  end
end
