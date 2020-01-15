class RateLimitChecker
  attr_reader :user, :action

  def self.daily_account_follow_limit
    SiteConfig.rate_limit_follow_count_daily
  end

  def initialize(user = nil)
    @user = user
  end

  UploadRateLimitReached = Class.new(StandardError)
  DailyFollowAccountLimitReached = Class.new(StandardError)

  def limit_by_action(action)
    check_method = "check_#{action}_limit"
    result = respond_to?(check_method) ? public_send(check_method) : false

    if result
      @action = action
      ping_admins
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
    EmailMessage.where(to: address).
      where("sent_at > ?", 2.minutes.ago).size > 5
  end

  def ping_admins
    RateLimitCheckerWorker.perform_async(user.id, action)
  end

  def check_comment_creation_limit
    user.comments.where("created_at > ?", 30.seconds.ago).size > 9
  end

  def check_published_article_creation_limit
    user.articles.published.where("created_at > ?", 30.seconds.ago).size > 9
  end

  def check_image_upload_limit
    Rails.cache.read("#{user.id}_image_upload").to_i > 9
  end

  def check_follow_account_limit
    user_today_follow_count > self.class.daily_account_follow_limit
  end

  private

  def user_today_follow_count
    following_users_count = user.following_users_count
    return following_users_count if following_users_count < self.class.daily_account_follow_limit
  end
end
