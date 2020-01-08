class CannedResponsePolicy < ApplicationPolicy
  def index?
    user_is_moderator?
  end

  def create?
    true
  end

  def destroy?
    user_is_owner?
  end

  def update?
    user_is_owner? || user_is_moderator?
  end

  def permitted_attributes
    %i[type_of content_type content title]
  end

  private

  def user_is_owner?
    user.id == record.user_id
  end

  def user_is_moderator?
    user.any_admin? || user.moderator_for_tags&.present?
  end
end
