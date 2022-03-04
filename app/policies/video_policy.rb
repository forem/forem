class VideoPolicy < ApplicationPolicy
  def new?
    return false unless Settings::General.enable_video_upload
    return false if user.suspended?
    return false unless user.created_at

    user.created_at.before?(2.weeks.ago)
  end

  alias create? new?
end
