class BadgePolicy < ApplicationPolicy
  def api?
    user&.administrative_access_to?(resource: Badge)
  end
end
