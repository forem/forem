class ResponseTemplatePolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[content_type content title].freeze

  class Scope < Scope
    def resolve
      if Authorizer.for(user: user).accesses_mod_response_templates?
        scope.where(user: user, type_of: "personal_comment").or(scope.where.not(type_of: "personal_comment"))
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

  def modify?
    return true if mod_comment? && user_trusted?

    user_owner?
  end

  alias update? modify?
  alias destroy? modify?

  def permitted_attributes_for_create
    if user_trusted?
      PERMITTED_ATTRIBUTES + [:type_of]
    else
      PERMITTED_ATTRIBUTES
    end
  end

  def permitted_attributes_for_update
    PERMITTED_ATTRIBUTES
  end

  private

  def user_owner?
    user.id == record.user_id
  end

  def user_trusted?
    Authorizer.for(user: user).accesses_mod_response_templates?
  end

  def user_moderator?
    user_any_admin? || user.super_moderator? || user.moderator_for_tags&.present?
  end

  def mod_comment?
    record.type_of == "mod_comment"
  end
end
