# frozen_string_literal: true

require_relative "ci_test_cycle"
require_relative "evp_proxy"
require_relative "../http"
require_relative "../../ext/transport"

module Datadog
  module CI
    module Transport
      module Api
        module Builder
          def self.build_ci_test_cycle_api(settings)
            dd_site = settings.site || Ext::Transport::DEFAULT_DD_SITE
            url = settings.ci.agentless_url ||
              "https://#{Ext::Transport::TEST_VISIBILITY_INTAKE_HOST_PREFIX}.#{dd_site}:443"

            uri = URI.parse(url)
            raise "Invalid agentless mode URL: #{url}" if uri.host.nil?

            http = Datadog::CI::Transport::HTTP.new(
              host: uri.host,
              port: uri.port,
              ssl: uri.scheme == "https" || uri.port == 443,
              compress: true
            )

            CiTestCycle.new(api_key: settings.api_key, http: http)
          end

          def self.build_evp_proxy_api(agent_settings)
            http = Datadog::CI::Transport::HTTP.new(
              host: agent_settings.hostname,
              port: agent_settings.port,
              ssl: agent_settings.ssl,
              timeout: agent_settings.timeout_seconds,
              compress: false
            )

            EvpProxy.new(http: http)
          end
        end
      end
    end
  end
end
