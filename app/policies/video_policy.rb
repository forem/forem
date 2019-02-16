class VideoPolicy < ApplicationPolicy
  def new?
    user.created_at < 2.weeks.ago
  end

  def create?
    user.created_at < 2.weeks.ago
  end
end
