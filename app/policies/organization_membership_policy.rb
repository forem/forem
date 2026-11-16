class OrganizationMembershipPolicy < ApplicationPolicy
  # Responding to an invitation is up to the invitee alone.
  # @return [Boolean]
  def accept?
    require_user!
    invitee?
  end

  # @return [Boolean]
  def decline?
    require_user!
    invitee?
  end

  private

  # @return [Boolean] whether the signed-in user is the one who was invited
  def invitee?
    record.user_id == user.id
  end
end
