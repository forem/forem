class DiscussionLockPolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[article_id notes reason].freeze

  def create?
    (user_author? || minimal_admin?) && !user_suspended?
  end

  def destroy?
    create?
  end

  def permitted_attributes
    PERMITTED_ATTRIBUTES
  end

  private

  def user_author?
    record.locking_user_id == user.id
  end
end
