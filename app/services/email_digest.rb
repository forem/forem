class EmailDigest
  def self.send_periodic_digest_email(users = [], starting_id = 1, ending_id = 50_000_000)
    new(users, starting_id, ending_id).send_periodic_digest_email
  end

  def initialize(users = [], starting_id = 1, ending_id = 50_000_000)
    @users = users.empty? ? get_users(starting_id, ending_id) : users
  end

  def send_periodic_digest_email
    @users.select(:id).in_batches do |batch|
      batch.each do |user|
        # Temporary
        # @sre:mstruve This is temporary until we have an efficient way to handle this job
        # for our large DEV community. Smaller Forems should be able to handle it no problem
        if ForemInstance.dev_to?
          Emails::SendUserDigestWorker.new.perform(user.id)
        else
          Emails::SendUserDigestWorker.perform_async(user.id)
        end
      end
    end
  end

  private

  def get_users(starting_id, ending_id)
    User.registered.joins(:notification_setting)
      .where(notification_setting: { email_digest_periodic: true })
      .where.not(email: "")
      .where("users.id >= ? AND users.id <= ?", starting_id, ending_id)
  end
end
