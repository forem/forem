class ReactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    !user_is_banned?
  end
end
