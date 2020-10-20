class VideoPolicy < ApplicationPolicy
  def create?
    user.created_at < 2.weeks.ago if user.created_at
  end

  def enabled?
    new? && SiteConfig.enable_video_upload
  end

  private

  def new?
    user.created_at < 2.weeks.ago if user.created_at
  end
end
