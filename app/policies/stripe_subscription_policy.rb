class StripeSubscriptionPolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  def update?
    !user_is_banned?
  end

  def destroy?
    true
  end
end
