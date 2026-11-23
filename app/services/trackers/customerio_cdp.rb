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
    # Customer.io drops any call over 32 KB and still answers 200, so batch
    # events stay well under it: at most this many recipients per call, halved
    # while the serialized properties exceed the byte budget.
    MAX_BATCH_RECIPIENTS = 1_000
    MAX_BATCH_PROPERTIES_BYTES = 24.kilobytes

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

      event = Trackable::EventName.prefixed(event_name)

      ids.each do |id|
        attributes = {
          anonymous_id: "dev:#{id}",
          event: event,
          properties: properties,
          timestamp: timestamp
        }
        mlh_uid = linked_uids[id] || (properties["mlh_user_id"].presence if destructive)
        attributes[:user_id] = mlh_uid if mlh_uid
        client.track(attributes)
      end
    end

    # One event about many users, keyed on a fixed anonymous_id rather than any
    # person's profile. Recipients are narrowed to accounts linked to an MLH
    # identity (the only ones the CDP's consumer can resolve, and the only ones
    # whose ids should leave Forem), then chunked into one call each; every
    # chunk carries recipient_user_ids, chunk_index and chunk_count, and each
    # recipient property as an array aligned with recipient_user_ids.
    def track_batch(event_name:, properties:, anonymous_id:, recipient_ids: nil, recipient_properties: {},
                    timestamp: nil)
      event = Trackable::EventName.prefixed(event_name)
      return send_batch_call(event, properties, anonymous_id, timestamp) if recipient_ids.nil?

      recipients = linked_recipients(recipient_ids, recipient_properties)
      return if recipients.empty?

      chunks = recipients.each_slice(MAX_BATCH_RECIPIENTS).flat_map { |slice| fit_batch_chunk(properties, slice) }
      chunks.each_with_index do |chunk, index|
        chunk_properties = properties.merge(recipient_columns(chunk))
          .merge("chunk_index" => index, "chunk_count" => chunks.size)
        send_batch_call(event, chunk_properties, anonymous_id, timestamp)
      end
    end

    def flush
      @client&.flush
    end

    private

    def send_batch_call(event, properties, anonymous_id, timestamp)
      client.track(anonymous_id: anonymous_id, event: event, properties: properties, timestamp: timestamp)
    end

    # One hash per linked recipient, ascending by user id, holding its user id
    # and its value of each recipient property.
    def linked_recipients(recipient_ids, recipient_properties)
      linked_ids = Identity.where(provider: "mlh", user_id: recipient_ids).distinct.pluck(:user_id).to_set
      recipients = recipient_ids.each_with_index.filter_map do |id, index|
        next unless linked_ids.include?(id)

        { "recipient_user_ids" => id }.merge(recipient_properties.transform_values { |values| values[index] })
      end
      recipients.uniq { |recipient| recipient["recipient_user_ids"] }
        .sort_by { |recipient| recipient["recipient_user_ids"] }
    end

    def recipient_columns(chunk)
      chunk.first.keys.index_with { |key| chunk.pluck(key) }
    end

    def fit_batch_chunk(properties, chunk)
      return [chunk] if chunk.size == 1
      return [chunk] if properties.merge(recipient_columns(chunk)).to_json.bytesize <= MAX_BATCH_PROPERTIES_BYTES

      chunk.each_slice((chunk.size / 2.0).ceil).flat_map { |half| fit_batch_chunk(properties, half) }
    end

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
