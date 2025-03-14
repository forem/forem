class AlgoliaInsightsService
  include HTTParty
  base_uri "https://insights.algolia.io/1"

  def initialize(application_id = nil, api_key = nil)
    @application_id = application_id || Settings::General.algolia_application_id
    @api_key = api_key || Settings::General.algolia_api_key
  end

  def track_event(event_type, event_name, user_id, object_id, index_name, timestamp = nil, query_id = nil, positions = [1])
    headers = {
      "X-Algolia-Application-Id" => @application_id,
      "X-Algolia-API-Key" => @api_key,
      "Content-Type" => "application/json"
    }
    payload = {
      events: [
        {
          eventType: event_type,
          eventName: event_name,
          index: index_name,
          userToken: user_id.to_s,
          objectIDs: [object_id.to_s],
          timestamp: timestamp || (Time.current.to_i * 1000),
          positions: positions,
          queryID: query_id
        },
      ]
    }

    response = self.class.post("/events", headers: headers, body: payload.to_json)
    if response.success?
      Rails.logger.debug { "Event tracked: #{response.body}" }
    else
      Rails.logger.debug { "Failed to track event: #{response.body}" }
    end
  end
end
