class StripeSubscriptionPolicy < ApplicationPolicy
  def create?
    !user_suspended?
  end

  alias update? create?

  def destroy?
    true
  end
end
