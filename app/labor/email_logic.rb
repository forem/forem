class EmailLogic
  attr_reader :open_percentage, :last_email_sent_at, :days_until_next_email, :articles_to_send

  def initialize(user)
    @user = user
    @open_percentage = nil
    @ready_to_receive_email = nil
    @last_email_sent_at = nil
    @days_until_next_email = nil
    @articles_to_send = []
  end

  def analyze
    @last_email_sent_at = get_last_digest_email_user_received
    @open_percentage = get_open_rate
    @days_until_next_email = get_days_until_next_email
    @ready_to_receive_email = get_user_readiness
    @articles_to_send = get_articles_to_send if @ready_to_receive_email
    self
  end

  def should_receive_email?
    @ready_to_receive_email
  end

  private

  def get_articles_to_send
    fresh_date = get_fresh_date

    articles = if user_has_followings?
                 experience_level_rating = (@user.experience_level || 5)
                 experience_level_rating_min = experience_level_rating - 3.6
                 experience_level_rating_max = experience_level_rating + 3.6

                 @user.followed_articles.
                   where("published_at > ?", fresh_date).
                   where(published: true, email_digest_eligible: true).
                   where.not(user_id: @user.id).
                   where("score > ?", 12).
                   where("experience_level_rating > ? AND experience_level_rating < ?",
                         experience_level_rating_min, experience_level_rating_max).
                   order("score DESC").
                   limit(8)
               else
                 Article.published.
                   where("published_at > ?", fresh_date).
                   where(featured: true, email_digest_eligible: true).
                   where.not(user_id: @user.id).
                   where("score > ?", 25).
                   order("score DESC").
                   limit(8)
               end

    @ready_to_receive_email = false if articles.length < 3

    articles
  end

  def get_days_until_next_email
    # Relies on hyperbolic tangent function to model the frequency of the digest email
    max_day = SiteConfig.periodic_email_digest_max
    min_day = SiteConfig.periodic_email_digest_min
    result = max_day * (1 - Math.tanh(2 * @open_percentage))
    result = result.round
    result < min_day ? min_day : result
  end

  def get_open_rate
    past_sent_emails = @user.email_messages.where(mailer: "DigestMailer#digest_email").limit(10)

    past_sent_emails_count = past_sent_emails.count

    # Will stick with 50% open rate if @user has no/not-enough email digest history
    return 0.5 if past_sent_emails_count < 10

    past_opened_emails_count = past_sent_emails.where("opened_at IS NOT NULL").count
    past_opened_emails_count / past_sent_emails_count
  end

  def get_user_readiness
    return true unless @last_email_sent_at

    # Has it been at least x days since @user received an email?
    Time.current - @last_email_sent_at >= @days_until_next_email.days.to_i
  end

  def get_last_digest_email_user_received
    @user.email_messages.where(mailer: "DigestMailer#digest_email").last&.sent_at
  end

  def get_fresh_date
    a_few_days_ago = 4.days.ago.utc
    return a_few_days_ago unless @last_email_sent_at

    a_few_days_ago > @last_email_sent_at ? a_few_days_ago : @last_email_sent_at
  end

  def user_has_followings?
    following_users = @user.cached_following_users_ids
    following_tags = @user.cached_followed_tag_names
    following_users.any? || following_tags.any?
  end
end
