class RateLimitChecker
  attr_reader :user, :action

  def initialize(user = nil)
    @user = user
  end

  class UploadRateLimitReached < StandardError; end
  class DailyFollowAccountLimitReached < StandardError; end

  def limit_by_action(action)
    check_method = "check_#{action}_limit"
    result = respond_to?(check_method, true) ? send(check_method) : false

    if result
      @action = action

      Slack::Messengers::RateLimit.call(user: user, action: action)
    end
    result
  end

  def track_image_uploads
    count = Rails.cache.read("#{@user.id}_image_upload").to_i
    count += 1
    Rails.cache.write("#{@user.id}_image_upload", count, expires_in: 30.seconds)
  end

  def limit_by_email_recipient_address(address)
    # This is related to the recipient, not the "user" initiator, like in action.
    EmailMessage.where(to: address).where("sent_at > ?", 2.minutes.ago).size >
      SiteConfig.rate_limit_email_recipient
  end

  private

  def check_comment_creation_limit
    user.comments.where("created_at > ?", 30.seconds.ago).size >
      SiteConfig.rate_limit_comment_creation
  end

  def check_published_article_creation_limit
    user.articles.published.where("created_at > ?", 30.seconds.ago).size >
      SiteConfig.rate_limit_published_article_creation
  end

  def check_image_upload_limit
    Rails.cache.read("#{user.id}_image_upload").to_i >
      SiteConfig.rate_limit_image_upload
  end

  def check_follow_account_limit
    user_today_follow_count > SiteConfig.rate_limit_follow_count_daily
  end

  def user_today_follow_count
    following_users_count = user.following_users_count
    return following_users_count if following_users_count < SiteConfig.rate_limit_follow_count_daily

    now = Time.zone.now
    user.follows.where(created_at: (now.beginning_of_day..now)).size
  end
end
