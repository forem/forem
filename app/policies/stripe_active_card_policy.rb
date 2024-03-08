class StripeActiveCardPolicy < ApplicationPolicy
  def create?
    !user.spam_or_suspended?
  end

  alias update? create?

  def destroy?
    true
  end
end
