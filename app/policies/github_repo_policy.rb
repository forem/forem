class GithubRepoPolicy < ApplicationPolicy
  def create?
    !user.banned
  end

  def update?
    !user.banned && user_is_owner?
  end

  def permitted_attributes
    %i[github_id_code]
  end

  private

  def user_is_owner?
    record.user_id == user.id
  end
end
