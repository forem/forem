# Temporary
# @sre:mstruve This is temporary until we have an efficient way to handle this task
# in Sidekiq for our large DEV community.
task send_email_digest: :environment do
  if Time.current.wday.between?(1, 5)
    EmailDigest.send_periodic_digest_email([], 1, 750_000)
  end
end

task send_email_digest_second_chunk: :environment do
  if Time.current.wday.between?(1, 5)
    EmailDigest.send_periodic_digest_email([], 750_001, 1_500_000)
  end
end

task send_email_digest_third_chunk: :environment do
  if Time.current.wday.between?(1, 5)
    EmailDigest.send_periodic_digest_email([], 1_500_001)
  end
end
