class EndorsementPolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  def update?
    user_is_author?
  end

  def destroy?
    update?
  end

  def permitted_attributes
    %i[classified_listing_id message]
  end

  private

  def user_is_author?
    record.user_id == user.id
  end
end
