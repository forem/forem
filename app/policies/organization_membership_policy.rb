class OrganizationMembershipPolicy < ApplicationPolicy
  # Responding to an invitation is up to the invitee alone.
  def accept?
    require_user!
    invitee?
  end

  def decline?
    require_user!
    invitee?
  end

  private

  def invitee?
    record.user_id == user.id
  end
end
