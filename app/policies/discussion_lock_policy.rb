class DiscussionLockPolicy < ApplicationPolicy
  def create?
    authorized_user?
  end

  def destroy?
    create?
  end

  def permitted_attributes
    %i[article_id notes reason]
  end

  private

  def authorized_user?
    user_author? || minimal_admin?
  end

  def user_author?
    record.locking_user_id == user.id
  end
end
