class FollowPolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[id explicit_points].freeze

  def create?
    !user_is_banned?
  end

  # record is an object of ActiveRecord_Relation
  def bulk_update?
    record.all? { |follow| user_is_follower?(follow) }
  end

  def permitted_attributes
    PERMITTED_ATTRIBUTES
  end

  private

  def user_is_follower?(follow)
    follow.follower_id == user.id && follow.follower_type == "User"
  end
end
