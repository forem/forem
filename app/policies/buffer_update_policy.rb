class BufferUpdatePolicy < ApplicationPolicy
  def create?
    user_is_trusted?
  end
end
