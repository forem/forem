module AlgoliaInsights
  # Sends an event to the Algolia Insights API outside the request cycle, so
  # telemetry endpoints (/page_views, /reactions, /insights) do not hold a web
  # thread open on the external HTTP round-trip or its 5s timeout.
  # A single attempt (retry: false), matching the previous inline call: retrying
  # could double-count an event Algolia already accepted.
  class TrackEventWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: false, tags: ["algolia"]

    def perform(event_type, event_name, user_id, object_id, index_name, timestamp = nil, query_id = nil,
                positions = [1], subforem_id = nil)
      if subforem_id
        RequestStore.store[:subforem_id] = subforem_id
        RequestStore.store[:default_subforem_id] ||= Subforem.cached_default_id
      end

      AlgoliaInsightsService.new.track_event(
        event_type,
        event_name,
        user_id,
        object_id,
        index_name,
        timestamp,
        query_id,
        positions,
      )
    end
  end
end
