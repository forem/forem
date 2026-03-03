class AgentSessionPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

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
    return true if record.published?

    require_user!
    record.user_id == user.id || user_any_admin?
  end

  def edit?
    require_user!
    record.user_id == user.id
  end

  def update?
    require_user!
    record.user_id == user.id
  end

  def destroy?
    require_user!
    record.user_id == user.id || user_any_admin?
  end
end
