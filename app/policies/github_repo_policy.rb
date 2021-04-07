class GithubRepoPolicy < ApplicationPolicy
  def index?
    !user_suspended? && user.authenticated_through?(:github)
  end

  def update_or_create?
    !user_suspended? && user.authenticated_through?(:github)
  end

  def permitted_attributes
    %i[github_id_code featured]
  end
end
