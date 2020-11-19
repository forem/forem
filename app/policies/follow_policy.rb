class FollowPolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  # record is an object of ActiveRecord_Relation
  def bulk_update?
    record.all? { |follow| user_is_follower?(follow) }
  end

  def permitted_attributes
    %i[id points]
  end

  private

  def user_is_follower?(follow)
    follow.follower_id == user.id && follow.follower_type == "User"
  end
end
