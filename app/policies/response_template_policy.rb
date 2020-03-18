class ResponseTemplatePolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[content_type content title].freeze

  def admin_index?
    minimal_admin?
  end

  def moderator_index?
    user_is_moderator?
  end

  def create?
    true
  end

  # comes from comments_controller
  def moderator_create?
    user_is_moderator? && record_is_mod_comment?
  end

  def destroy?
    user_is_owner?
  end

  def update?
    user_is_owner?
  end

  def permitted_attributes_for_create
    PERMITTED_ATTRIBUTES
  end

  def permitted_attributes_for_update
    PERMITTED_ATTRIBUTES
  end

  private

  def user_is_owner?
    user.id == record.user_id
  end

  def user_is_moderator?
    minimal_admin? || user.moderator_for_tags&.present?
  end

  def record_is_mod_comment?
    record.type_of == "mod_comment"
  end
end
