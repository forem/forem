class RssFeedPolicy < ApplicationPolicy
  def create?
    !user.spam_or_suspended?
  end

  def update?
    user_owner? && !user.spam_or_suspended?
  end

  def destroy?
    user_owner? && !user.spam_or_suspended?
  end

  def fetch?
    user_owner? && !user.spam_or_suspended?
  end

  private

  def user_owner?
    user.id == record.user_id
  end
end
