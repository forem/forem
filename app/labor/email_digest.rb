class EmailDigest
  def self.send_periodic_digest_email(users = [])
    new(users).send_periodic_digest_email
  end

  def initialize(users = [])
    @users = users.empty? ? get_users : users
  end

  def send_periodic_digest_email
    @users.ids.each do |user_id|
      Email::SendUserDigestWorker.perform_async(user_id)
    end
  end

  private

  def get_users
    User.registered.where(email_digest_periodic: true).where.not(email: "")
  end
end
