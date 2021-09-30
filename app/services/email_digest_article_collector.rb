class EmailDigestArticleCollector
  include Instrumentation

  ARTICLES_TO_SEND = "EmailDigestArticleCollector#articles_to_send".freeze

  def initialize(user)
    @user = user
  end

  def articles_to_send
    # rubocop:disable Metrics/BlockLength
    instrument ARTICLES_TO_SEND, tags: { user_id: @user.id } do
      return [] unless should_receive_email?

      articles = if user_has_followings?
                   experience_level_rating = (@user.setting.experience_level || 5)
                   experience_level_rating_min = experience_level_rating - 3.6
                   experience_level_rating_max = experience_level_rating + 3.6

                   @user.followed_articles
                     .select(:title, :description, :path)
                     .published
                     .where("published_at > ?", cutoff_date)
                     .where(email_digest_eligible: true)
                     .where.not(user_id: @user.id)
                     .where("score > ?", 12)
                     .where("experience_level_rating > ? AND experience_level_rating < ?",
                            experience_level_rating_min, experience_level_rating_max)
                     .order(score: :desc)
                     .limit(6)
                 else
                   Article.select(:title, :description, :path)
                     .published
                     .where("published_at > ?", cutoff_date)
                     .where(featured: true, email_digest_eligible: true)
                     .where.not(user_id: @user.id)
                     .where("score > ?", 25)
                     .order(score: :desc)
                     .limit(6)
                 end

      articles.length < 3 ? [] : articles
    end
    # rubocop:enable Metrics/BlockLength
  end

  private

  def should_receive_email?
    return true unless last_email_sent_at

    # Has it been at least x days since @user received an email?
    Time.current - last_email_sent_at >= Settings::General.periodic_email_digest
  end

  def last_email_sent_at
    last_user_emails.last&.sent_at
  end

  def cutoff_date
    a_few_days_ago = 4.days.ago.utc
    return a_few_days_ago unless last_email_sent_at

    [a_few_days_ago, last_email_sent_at].max
  end

  def user_has_followings?
    @user.following_users_count.positive? ||
      @user.cached_followed_tag_names.any? ||
      @user.cached_antifollowed_tag_names.any?
  end

  def last_user_emails
    @last_user_emails ||= @user.email_messages.select(:sent_at).where(mailer: "DigestMailer#digest_email").limit(10)
  end
end
