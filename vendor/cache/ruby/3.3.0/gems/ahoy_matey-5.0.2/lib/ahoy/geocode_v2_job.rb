module Ahoy
  class GeocodeV2Job < ActiveJob::Base
    queue_as { Ahoy.job_queue }

    def perform(visit_token, ip)
      location =
        begin
          Geocoder.search(ip).first
        rescue NameError
          raise "Add the geocoder gem to your Gemfile to use geocoding"
        rescue => e
          Ahoy.log "Geocode error: #{e.class.name}: #{e.message}"
          nil
        end

      if location && location.country.present?
        data = {
          country: location.country,
          country_code: location.try(:country_code).presence,
          region: location.try(:state).presence,
          city: location.try(:city).presence,
          postal_code: location.try(:postal_code).presence,
          latitude: location.try(:latitude).presence,
          longitude: location.try(:longitude).presence
        }

        Ahoy::Tracker.new(visit_token: visit_token).geocode(data)
      end
    end
  end
end
