class BadgeAchievementPolicy < ApplicationPolicy
  def api?
    user&.administrative_access_to?(resource: BadgeAchievement)
  end
end
