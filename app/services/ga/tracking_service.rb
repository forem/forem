module Ga
  class TrackingService
    include HTTParty
    base_uri "https://www.google-analytics.com"

    def initialize(measurement_id, api_secret, client_id)
      @measurement_id = measurement_id
      @api_secret = api_secret
      @client_id = client_id
    end

    def track_event(event_name, params = {}) # rubocop:disable Style/OptionHash
      payload = {
        client_id: @client_id,
        events: [
          {
            name: event_name,
            params: params
          },
        ]
      }

      # raise payload.inspect.to_s

      options = {
        query: {
          measurement_id: @measurement_id,
          api_secret: @api_secret
        },
        headers: { "Content-Type" => "application/json" },
        body: payload.to_json
      }

      self.class.post("/mp/collect", options)
    end
  end
end
