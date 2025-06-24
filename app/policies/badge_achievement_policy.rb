class BadgeAchievementPolicy < ApplicationPolicy
  def api?
    user&.any_admin?
  end
end