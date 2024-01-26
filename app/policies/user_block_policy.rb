class UserBlockPolicy < ApplicationPolicy
  def create?
    !user.spam_or_suspended?
  end

  alias destroy? create?

  def permitted_attributes
    %i[id blocked_id]
  end
end
