class MessagePolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  private

  def user_is_banned?
    user&.has_role?(:banned)
  end
end
