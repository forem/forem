class DiscussionLockPolicy < ApplicationPolicy
  def create?
    user_author? || minimal_admin?
  end

  def destroy?
    create?
  end

  def permitted_attributes
    %i[article_id notes reason]
  end

  private

  def user_author?
    record.locking_user_id == user.id
  end
end
