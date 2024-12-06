# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Teamcity: https://www.jetbrains.com/teamcity/
          # Environment variables docs: https://www.jetbrains.com/help/teamcity/predefined-build-parameters.html
          class Teamcity < Base
            def self.handles?(env)
              env.key?("TEAMCITY_VERSION")
            end

            def provider_name
              "teamcity"
            end

            def job_name
              env["TEAMCITY_BUILDCONF_NAME"]
            end

            def job_url
              env["BUILD_URL"]
            end
          end
        end
      end
    end
  end
end
