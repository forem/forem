class FavoritePolicy < ApplicationPolicy
  def create?
    require_user_in_good_standing!

    true
  end
end
