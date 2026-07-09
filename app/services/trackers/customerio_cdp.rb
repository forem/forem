module Trackers
  # Customer.io CDP (formerly Data Pipelines) adapter. The Pipelines API is
  # Segment-compatible; we use the analytics-ruby gem pointed at cdp.customer.io.
  #
  # Configure via ENV:
  #   CUSTOMERIO_CDP_WRITE_KEY  required; absence leaves the adapter disabled
  #   CUSTOMERIO_CDP_HOST       optional override; defaults to cdp.customer.io
  class CustomerioCdp < Base
    DEFAULT_HOST = "cdp.customer.io".freeze
    # Customer.io CDP does not implement analytics-ruby's default /v1/import
    # path (404); its Segment-compatible batch endpoint is /v1/batch.
    BATCH_PATH = "/v1/batch".freeze

    def enabled?
      # Resolve the setting via the default subforem (like mailers do): the admin
      # panel saves settings scoped to the request's subforem, and outside a request
      # (Sidekiq, console) a bare read would only see the global row.
      ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"].present? &&
        Settings::General.customerio_cdp_enabled(subforem_id: Subforem.cached_default_id)
    end

    # People are identified by email rather than DEV user id: ids are not synced
    # to the Core consumer yet. Emails are resolved at send time so they are
    # current — but destructive events (user_gdpr_deleted) fire after the row
    # is destroyed, so when no row matches we fall back to the payload's own
    # email rather than silently dropping the one event whose point is that
    # the user no longer exists.
    def track(event_name:, user_ids:, properties:, timestamp: nil)
      emails = User.where(id: Array.wrap(user_ids)).pluck(:email)
      emails = [properties["email"]] if emails.empty?
      emails.each do |email|
        next if email.blank?

        client.track(
          user_id: email,
          event: event_name,
          properties: properties,
          timestamp: timestamp,
        )
      end
    end

    private

    def client
      @client ||= Segment::Analytics.new(
        write_key: ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"],
        host: ApplicationConfig["CUSTOMERIO_CDP_HOST"].presence || DEFAULT_HOST,
        path: BATCH_PATH,
      )
    end
  end
end
