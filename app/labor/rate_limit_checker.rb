class RateLimitChecker
  attr_accessor :user
  def initialize(user = nil)
    @user = user
  end

  def limit_by_situation(situation)
    result = case situation
             when "comment_creation"
               user.comments.where("created_at > ?", 30.seconds.ago).size > 9
             when "published_article_creation"
               user.articles.published.where("created_at > ?", 30.seconds.ago).size > 9
             else
               false
             end
    ping_admins if result == true
    result
  end

  def limit_by_email_recipient_address(address)
    # This is related to the recipient, not the "user" initiator, like in situation.
    EmailMessage.where(to: address).
      where("sent_at > ?", 2.minutes.ago).size > 5
  end

  def ping_admins
    Labor::RateLimitCheckerJob.perform_later(user.id)
  end

  def ping_admins_without_delay
    Labor::RateLimitCheckerJob.perform_now(user.id)
  end
end
