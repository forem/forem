module Customerio
  # Backfills ahoy_messages.clicked_at from Customer.io's click-tracking
  # webhook (see IncomingWebhooks::CustomerioEventsController), since clicks
  # on Customer.io-rendered emails never hit Ahoy's own click endpoint.
  class RecordEmailClickWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority

    def perform(delivery_id, event_timestamp)
      message = EmailMessage.find_by(cio_delivery_id: delivery_id)
      return unless message
      return if message.clicked_at.present?

      message.update_column(:clicked_at, parse_timestamp(event_timestamp))
    end

    private

    # Customer.io sends the event timestamp as a Unix epoch (seconds); fall
    # back to now if it's missing or unparseable rather than dropping the click.
    def parse_timestamp(event_timestamp)
      return Time.current if event_timestamp.blank?

      Time.zone.at(Integer(event_timestamp))
    rescue ArgumentError, TypeError
      Time.current
    end
  end
end
