class VideoPolicy < ApplicationPolicy
  def new?
    user.has_role?(:video_permission)
  end

  def create?
    user.has_role?(:video_permission)
  end
end
