class MessagePolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  def destroy?
    user_is_sender?
  end

  private

  def user_is_sender?
    record.user_id == user.id
  end
end
