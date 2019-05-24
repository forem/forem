class ClassifiedListingPolicy < ApplicationPolicy
  def edit?
    user_is_author?
  end

  def update?
    user_is_author?
  end

  def authorized_organization_poster?
    OrganizationMembership.exists?(user: user, organization_id: record.organization_id, type_of_user: %w[admin member])
  end

  private

  def user_is_author?
    record.user_id == user.id
  end
end
