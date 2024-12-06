# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      module Http
        module Ext
          HEADER_DD_API_KEY = 'DD-API-KEY'
          HEADER_CONTENT_TYPE = 'Content-Type'
          HEADER_CONTENT_LENGTH = 'Content-Length'
          HEADER_DD_TELEMETRY_API_VERSION = 'DD-Telemetry-API-Version'
          HEADER_DD_TELEMETRY_REQUEST_TYPE = 'DD-Telemetry-Request-Type'

          CONTENT_TYPE_APPLICATION_JSON = 'application/json'
          API_VERSION = 'v1'

          AGENT_ENDPOINT = '/telemetry/proxy/api/v2/apmtelemetry'
        end
      end
    end
  end
end
