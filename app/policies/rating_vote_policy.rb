class RatingVotePolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end

  def permitted_attributes
    %i[rating group article_id]
  end
end
