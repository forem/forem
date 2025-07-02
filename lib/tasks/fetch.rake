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

task run_rollup: :environment do
  # This is a rake task to help catch up with old periods where the rollup
  # was not run or failed. Exists mostly for DEV-specific stuff and may be changed as different "catchup" tasks are needed.
  # Does not get called from within app anywhere.

  # Rolls up three days at a time, randomly. Technically "already rolled up days" might get rolled up again, but that's fine.
  puts "Let's roll"

  3.times do
    # Random date from 50-200 days ago
    date = Date.current - rand(50..200).days
    BillboardEventRollup.rollup date
  end
end