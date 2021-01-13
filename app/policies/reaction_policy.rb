class ReactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    !user_is_suspended?
  end
end
