# A campaign's end date and caps decide how long its billboards stay live, so changing a campaign
# that governs an approved or Event-owned billboard needs the same modify_approved clause that
# BillboardPolicy asks for when changing an approved billboard. Creating a campaign, or changing
# one whose billboards are all unapproved, needs nothing beyond Billboard access.
class BillboardCampaignPolicy < ApplicationPolicy
  def missing_sub_permissions(action)
    return [] unless action == :save && record.persisted? && record.changed? && governs_approved_billboard?
    return [] if user.sub_permission?(resource: Billboard, clause: "modify_approved")

    %w[modify_approved]
  end

  private

  def governs_approved_billboard?
    record.billboards.where(approved: true).or(record.billboards.where.not(event_id: nil)).exists?
  end
end
