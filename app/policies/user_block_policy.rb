class UserBlockPolicy < ApplicationPolicy
  def create?
    !user_suspended?
  end

  def destroy?
    !user_suspended?
  end

  def permitted_attributes
    %i[id blocked_id]
  end
end
