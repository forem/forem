class GithubRepoPolicy < ApplicationPolicy
  def index?
    user.authenticated_through?(:github) && !user_is_banned?
  end

  def create?
    user.authenticated_through?(:github) && !user_is_banned?
  end

  def update?
    user.authenticated_through?(:github) && !user_is_banned? && user_is_owner?
  end

  def update_or_create?
    user.authenticated_through?(:github) && !user_is_banned?
  end

  def permitted_attributes
    %i[github_id_code featured]
  end

  private

  def user_is_owner?
    record.user_id == user.id
  end
end
