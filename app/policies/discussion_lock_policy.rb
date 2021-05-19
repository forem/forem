class DiscussionLockPolicy < ApplicationPolicy
  def create?
    authorized_user?
  end

  def destroy?
    create?
  end

  def permitted_attributes
    %i[article_id reason]
  end

  private

  def authorized_user?
    user_author? || minimal_admin?
  end

  def user_author?
    record.user_id == user.id
  end
end
