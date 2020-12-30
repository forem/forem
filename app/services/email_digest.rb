class EmailDigest
  def self.send_periodic_digest_email(users = [])
    new(users).send_periodic_digest_email
  end

  def initialize(users = [])
    @users = users.empty? ? get_users : users
  end

  def send_periodic_digest_email
    @users.select(:id).in_batches do |batch|
      batch.each do |user|
        # Temporary
        # @sre:mstruve This is temporary until we have an efficient way to handle this job
        # for our large DEV community. Smaller Forems should be able to handle it no problem
        if SiteConfig.community_name == "DEV Community"
          Emails::SendUserDigestWorker.new.perform(user.id)
        else
          Emails::SendUserDigestWorker.perform_async(user.id)
        end
      end
    end
  end

  private

  def get_users
    User.registered.where(email_digest_periodic: true).where.not(email: "")
  end
end
