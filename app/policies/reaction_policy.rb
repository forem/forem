class ReactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    !user_suspended?
  end
end
