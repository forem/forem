class BadgePolicy < ApplicationPolicy
  def api?
    user&.admin?
  end
end