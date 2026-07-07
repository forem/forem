class EventSignupPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def create?
    user.present?
  end

  def destroy?
    user.present? && record.user_id == user.id
  end

  def status?
    true
  end
end
