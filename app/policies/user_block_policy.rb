class UserBlockPolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  def destroy?
    !user_is_banned?
  end

  def permitted_attributes
    %i[id blocked_id]
  end
end
