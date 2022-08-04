class CommentPolicy < ApplicationPolicy
  def edit?
    return false if user_suspended?

    user_author?
  end

  def destroy?
    user_author?
  end

  def create?
    !user_suspended? && !user.comment_suspended?
  end

  alias new? create?

  alias update? edit?

  alias delete_confirm? destroy?

  alias settings? edit?

  def preview?
    true
  end

  def moderate?
    return true if user.trusted?

    moderator_create?
  end

  def moderator_create?
    # NOTE: Here, when we say "moderator", we mean "tag_moderator"
    user_moderator? || user_any_admin?
  end

  def hide?
    user_commentable_author?
  end

  alias unhide? hide?

  def admin_delete?
    user_any_admin?
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
