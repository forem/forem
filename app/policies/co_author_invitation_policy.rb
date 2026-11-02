class CoAuthorInvitationPolicy < ApplicationPolicy
  # Searching your followers to invite them as co-authors.
  def candidates?
    require_user_in_good_standing!
    true
  end

  # Responding is up to the invitee alone.
  def accept?
    require_user_in_good_standing!
    invitee?
  end

  # Declining (or withdrawing after accepting) stays open to the invitee in any standing.
  def decline?
    require_user!
    invitee?
  end

  private

  def invitee?
    record.user_id == user.id
  end
end
