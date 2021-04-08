class ResponseTemplatePolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[content_type content title].freeze

  def index?
    true
  end

  def admin_index?
    minimal_admin?
  end

  def moderator_index?
    user_moderator?
  end

  def create?
    true
  end

  # comes from comments_controller
  def moderator_create?
    user_moderator? && mod_comment?
  end

  def destroy?
    user_owner?
  end

  def update?
    user_owner?
  end

  def permitted_attributes_for_create
    PERMITTED_ATTRIBUTES
  end

  def permitted_attributes_for_update
    PERMITTED_ATTRIBUTES
  end

  private

  def user_owner?
    user.id == record.user_id
  end

  def user_moderator?
    minimal_admin? || user.moderator_for_tags&.present?
  end

  def mod_comment?
    record.type_of == "mod_comment"
  end
end
