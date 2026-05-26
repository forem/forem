module Trackers
  # Customer.io CDP (formerly Data Pipelines) adapter. The Pipelines API is
  # Segment-compatible; we use the analytics-ruby gem pointed at cdp.customer.io.
  #
  # Configure via ENV:
  #   CUSTOMERIO_CDP_WRITE_KEY  required; absence leaves the adapter disabled
  #   CUSTOMERIO_CDP_HOST       optional override; defaults to cdp.customer.io
  class CustomerioCdp < Base
    DEFAULT_HOST = "cdp.customer.io".freeze

    def enabled?
      ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"].present?
    end

    def track(event_name:, user_ids:, properties:, timestamp: nil)
      Array.wrap(user_ids).each do |user_id|
        client.track(
          user_id: user_id.to_s,
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
      )
    end
  end
end
