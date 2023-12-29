class GithubRepoPolicy < ApplicationPolicy
  def index?
    !user.spam_or_suspended? && user.authenticated_through?(:github)
  end

  alias update_or_create? index?

  def permitted_attributes
    %i[github_id_code featured]
  end
end
