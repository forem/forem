# Temporary
# @sre:mstruve This is temporary until we have an efficient way to handle this task
# in Sidekiq for our large DEV community.
task send_email_digest: :environment do
  if Time.current.wday.between?(1, 5)
    EmailDigest.send_periodic_digest_email
  end
end
