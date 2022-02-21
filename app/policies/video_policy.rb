class VideoPolicy < ApplicationPolicy
  def new?
    user.created_at < 2.weeks.ago if user.created_at
  end

  alias create? new?

  def enabled?
    Settings::General.enable_video_upload
  end
end
