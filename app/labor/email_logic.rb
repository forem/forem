class EmailLogic
  attr_reader :open_percentage, :last_email_sent_at,
    :days_until_next_email, :articles_to_send

  def initialize(user)
    @user = user
    @open_percentage = nil
    @ready_to_receive_email = nil
    @last_email_sent_at = nil
    @days_until_next_email = nil
    @articles_to_send = []
  end

  def analyze
    @last_email_sent_at = get_last_digest_email_user_recieved
    @open_percentage = get_open_rate
    @days_until_next_email = get_days_until_next_email
    @ready_to_receive_email = get_user_readiness
    if @ready_to_receive_email
      @articles_to_send = get_articles_to_send
    end
    self
  end

  def should_receive_email?
    @ready_to_receive_email
  end

  private

  def get_articles_to_send
    fresh_date = get_fresh_date
    articles = if user_has_followings?
                 @user.followed_articles.
                   where("published_at > ?", fresh_date).
                   where(published: true).
                   where("positive_reactions_count > ?", 15).
                   order("positive_reactions_count DESC").
                   limit(6)
               else
                 Article.
                   where("published_at > ?", fresh_date).
                   where(published: true).
                   where("positive_reactions_count > ?", 30).
                   order("positive_reactions_count DESC").
                   limit(6)
               end
    if articles.length < 3
      @ready_to_receive_email = false
    end
    articles
  end

  def get_days_until_next_email
    # Relies on hyperbolic tangent function to model the frequency of the digest email
    max_day = ENV["PERIODIC_EMAIL_DIGEST_MAX"].to_i
    min_day = ENV["PERIODIC_EMAIL_DIGEST_MIN"].to_i
    result = max_day * (1 - Math.tanh(2 * @open_percentage))
    result = result.round
    result < min_day ? min_day : result
  end

  def get_open_rate
    past_sent_emails = @user.email_messages.where(mailer: "DigestMailer#digest_email").limit(10)

    # Will stick with 50% open rate if @user has no/not-enough email digest history
    return 0.5 if past_sent_emails.length < 10

    past_sent_emails_count = past_sent_emails.count
    past_opened_emails_count = past_sent_emails.where("opened_at IS NOT NULL").count
    past_opened_emails_count / past_sent_emails_count
  end

  def get_user_readiness
    return true unless @last_email_sent_at
    # Has it been atleast x days since @user receive an email?
    (Time.now.utc - @last_email_sent_at) >= @days_until_next_email.days.to_i
  end

  def get_last_digest_email_user_recieved
    @user.email_messages.where(mailer: "DigestMailer#digest_email").last&.sent_at
  end

  def get_fresh_date
    a_month_ago = 1.month.ago.utc
    return a_month_ago unless @last_email_sent_at
    a_month_ago > @last_email_sent_at ? a_month_ago : @last_email_sent_at
  end

  def user_has_followings?
    following_users = @user.cached_following_users_ids
    following_tags = @user.cached_followed_tag_names
    !following_users.empty? || !following_tags.empty?
  end
end
