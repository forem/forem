class ListingEndorsementPolicy < ApplicationPolicy
  def update?
    user_is_author?
  end

  private

  def user_is_author?
    record.listing.user_id == user.id
  end
end
