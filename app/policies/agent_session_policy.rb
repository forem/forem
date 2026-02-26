class AgentSessionPolicy < ApplicationPolicy
  def index?
    require_user_in_good_standing!
  end

  def new?
    require_user_in_good_standing!
  end

  def create?
    require_user_in_good_standing!
  end

  def show?
    record.user_id == user.id || user_any_admin?
  end

  def edit?
    record.user_id == user.id
  end

  def update?
    record.user_id == user.id
  end

  def destroy?
    record.user_id == user.id || user_any_admin?
  end
end
