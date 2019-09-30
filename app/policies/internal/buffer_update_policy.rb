class Internal::BufferUpdatePolicy < ApplicationPolicy
  def create?
    buffer_admin? || minimal_admin?
  end

  def update?
    buffer_admin? || minimal_admin?
  end

  private

  def buffer_admin?
    user.has_role?(:single_resource_admin, BufferUpdate)
  end
end
