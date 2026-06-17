class EventSignupPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    user.present? && record.user_id == user.id
  end
end
