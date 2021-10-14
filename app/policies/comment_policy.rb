class CommentPolicy < ApplicationPolicy
  def edit?
    user_author?
  end

  def create?
    !user_suspended? && !user.comment_suspended?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def delete_confirm?
    edit?
  end

  def settings?
    edit?
  end

  def preview?
    true
  end

  def moderator_create?
    user_moderator? || minimal_admin?
  end

  def hide?
    user_commentable_author?
  end

  def unhide?
    user_commentable_author?
  end

  def admin_delete?
    minimal_admin?
  end

  def permitted_attributes_for_update
    %i[body_markdown receive_notifications]
  end

  def permitted_attributes_for_preview
    %i[body_markdown]
  end

  def permitted_attributes_for_create
    %i[body_markdown commentable_id commentable_type parent_id]
  end

  def permitted_attributes_for_moderator_create
    %i[commentable_id commentable_type parent_id]
  end

  private

  def user_moderator?
    user.moderator_for_tags.present?
  end

  def user_author?
    record.user_id == user.id
  end

  def user_commentable_author?
    record.commentable.present? && record.commentable.user_id == user.id
  end
end
