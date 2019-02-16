class VideoPolicy < ApplicationPolicy
  def new?
    user.created_at < 2.weeks.ago if user.created_at
  end

  def create?
    user.created_at < 2.weeks.ago if user.created_at
  end
end
