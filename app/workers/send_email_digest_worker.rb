class SendEmailDigestWorker
  include Sidekiq::Worker

  sidekiq_options queue: :medium_priority, retry: 15

  def perform
    EmailDigest.send_periodic_digest_email
  end
end
