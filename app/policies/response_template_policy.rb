class ResponseTemplatePolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[content_type content title].freeze

  class Scope < Scope
    def resolve
      if user.has_trusted_role? || user.any_admin? || user.moderator? || user.tag_moderator?
        scope.where(user: user, type_of: "personal_comment") + scope.where.not(type_of: "personal_comment")
      else
        scope.where(user: user, type_of: "personal_comment")
      end
    end
  end

  def index?
    true
  end

  def admin_index?
    user_any_admin?
  end

  def moderator_index?
    user_moderator?
  end

  alias create? index?

  # comes from comments_controller
  def moderator_create?
    user_moderator? && mod_comment?
  end

  def destroy?
    user_owner?
  end

  alias update? destroy?

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
    user_any_admin? || user.moderator_for_tags&.present?
  end

  def mod_comment?
    record.type_of == "mod_comment"
  end
end
