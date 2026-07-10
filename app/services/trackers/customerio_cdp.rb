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
    # Events that fire after the user row is destroyed. Straggler events for
    # deleted users are otherwise dropped (they could resurrect state after a
    # GDPR erasure), so these are the only ones that deliver without a live
    # row — possible because identity comes from the stable anonymous id and
    # the payload's own mlh_user_id, both knowable post-destruction.
    DESTRUCTIVE_EVENTS = ["user_gdpr_deleted"].freeze

    def enabled?
      # Resolve the setting via the default subforem (like mailers do): the admin
      # panel saves settings scoped to the request's subforem, and outside a request
      # (Sidekiq, console) a bare read would only see the global row.
      ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"].present? &&
        Settings::General.customerio_cdp_enabled(subforem_id: Subforem.cached_default_id)
    end

    # Identity follows the Segment spec: every call carries a stable
    # anonymous_id ("dev:<DEV user id>"), plus user_id set to the canonical
    # MLH (Core) user id once the account is linked — sending both stitches
    # the pre-link anonymous history onto the person downstream. Email is
    # never an identity field; it travels in properties only.
    def track(event_name:, user_ids:, properties:, timestamp: nil)
      destructive = DESTRUCTIVE_EVENTS.include?(event_name)
      ids = deliverable_ids(Array.wrap(user_ids), destructive)
      # Send-time lookup so the link is current; for destructive events the
      # identity row died with the user, so the payload's pre-destruction
      # capture is the fallback.
      linked_uids = Identity.where(provider: "mlh", user_id: ids).pluck(:user_id, :uid).to_h

      ids.each do |id|
        attributes = {
          anonymous_id: "dev:#{id}",
          event: event_name,
          properties: properties,
          timestamp: timestamp
        }
        mlh_uid = linked_uids[id] || (properties["mlh_user_id"].presence if destructive)
        attributes[:user_id] = mlh_uid if mlh_uid
        client.track(**attributes)
      end
    end

    private

    def deliverable_ids(ids, destructive)
      return ids if destructive

      User.where(id: ids).ids
    end

    def client
      @client ||= Segment::Analytics.new(
        write_key: ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"],
        host: ApplicationConfig["CUSTOMERIO_CDP_HOST"].presence || DEFAULT_HOST,
        path: BATCH_PATH,
      )
    end
  end
end
