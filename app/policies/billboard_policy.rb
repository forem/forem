# Bespoke Billboard sub-permissions (see SubPermissions). A restricted Billboard admin can create
# and edit billboards that are not approved, and can take any billboard down by unpublishing or
# unapproving it, but needs a clause to put a billboard live or to change one a human approved.
class BillboardPolicy < ApplicationPolicy
  TAKE_DOWN_ATTRIBUTES = %w[published].freeze

  def save?
    missing_sub_permissions(:save).empty?
  end

  def destroy?
    missing_sub_permissions(:destroy).empty?
  end

  def missing_sub_permissions(action)
    required_sub_permissions(action).reject do |clause|
      user.sub_permission?(resource: Billboard, clause: clause)
    end
  end

  private

  def required_sub_permissions(action)
    return approved_in_database? ? %w[modify_approved] : [] if action == :destroy

    clauses = []
    clauses << "approve" if turns_on?(:approved)
    clauses << "publish" if turns_on?(:published)
    clauses << "modify_approved" if modifies_approved?
    clauses
  end

  def turns_on?(attribute)
    record.public_send(attribute) == true && (record.new_record? || record.attribute_in_database(attribute) != true)
  end

  def approved_in_database?
    record.persisted? && record.attribute_in_database(:approved) == true
  end

  def modifies_approved?
    approved_in_database? && record.approved == true && (record.changed - TAKE_DOWN_ATTRIBUTES).any?
  end
end
