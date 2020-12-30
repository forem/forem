module Emails
  class EnqueueDigestWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 15

    def perform
      # Temporary
      # @sre:mstruve This is temporary until we have an efficient way to handle this job
      # for our large DEV community. Smaller Forems should be able to handle it no problem
      return if SiteConfig.community_name == "DEV Community"

      EmailDigest.send_periodic_digest_email
    end
  end
end
