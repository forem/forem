class BufferUpdatePolicy < ApplicationPolicy
  def create?
    user_is_trusted? || user_is_author?
  end

  private

  def user_is_author?
    record.user_id == user.id
  end
end
