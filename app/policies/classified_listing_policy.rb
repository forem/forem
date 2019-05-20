class ClassifiedListingPolicy < ApplicationPolicy
  def edit?
    user_is_author?
  end

  def update?
    user_is_author?
  end

  private

  def user_is_author?
    record.user_id == user.id
  end
end
