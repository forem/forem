class Internal::CommentPolicy < ApplicationPolicy
  def index?
    comment_admin?
  end

  private

  def comment_admin?
    user.has_role?(:single_resource_admin, Comment) || user.has_role?(:super_admin) || user.has_role?(:admin)
  end
end
