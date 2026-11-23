class TagAdjustmentPolicy < ApplicationPolicy
  def destroy?
    require_user_in_good_standing!
    return true if user_any_admin? || user_super_moderator?
    return false unless user_trusted?
    return false unless record.is_a?(TagAdjustment) && record.user_id == user.id && record.tag.present?

    user.administrative_access_to?(resource: record.tag, role_name: :tag_moderator)
  end
end
