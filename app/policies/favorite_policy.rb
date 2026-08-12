class FavoritePolicy < ApplicationPolicy
  def create?
    require_user_in_good_standing!

    user_community_leader?
  end
end
