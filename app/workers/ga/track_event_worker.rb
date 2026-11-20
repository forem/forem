module Ga
  # Sends a fallback page_view to the GA4 Measurement Protocol outside the request cycle, so
  # GaEventsController#create doesn't hold a web thread open on the Google Analytics round-trip.
  # A single attempt, matching the previous inline call: retrying could double-count an event GA
  # already accepted.
  class TrackEventWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: false

    def perform(client_id, event_params)
      measurement_id = Settings::General.ga_analytics_4_id
      api_secret = Settings::General.ga_api_secret
      return if measurement_id.blank? || api_secret.blank?

      TrackingService.new(measurement_id, api_secret, client_id).track_event("page_view", event_params)
    end
  end
end
