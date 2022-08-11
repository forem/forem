class SpacePolicy < ApplicationPolicy
  def update?
    user_any_admin?
  end

  alias index? update?
end
