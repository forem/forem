class EmailDigest
  def self.send_periodic_digest_email(users = [])
    new(users).send_periodic_digest_email
  end

  def initialize(users = [])
    @users = users.empty? ? get_users : users
  end

  def send_periodic_digest_email
    @users.find_each do |user|
      user_email_heuristic = EmailLogic.new(user).analyze
      next unless user_email_heuristic.should_receive_email?

      articles = user_email_heuristic.articles_to_send
      begin
        next unless user.email_digest_periodic?

        DigestMailer.with(user: user, articles: articles).digest_email.deliver_now
      rescue StandardError => e
        Honeybadger.context({ user_id: user.id, article_ids: articles.map(&:id) })
        Honeybadger.notify(e)
      end
    end
  end

  private

  def get_users
    User.registered.where(email_digest_periodic: true).where.not(email: "")
  end
end
