# frozen_string_literal: true

require "json"

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Codefresh: https://codefresh.io/
          # Environment variables docs: https://codefresh.io/docs/docs/pipelines/variables/#export-variables-to-all-steps-with-cf_export
          class Codefresh < Base
            def self.handles?(env)
              env.key?("CF_BUILD_ID")
            end

            def provider_name
              "codefresh"
            end

            def job_name
              env["CF_STEP_NAME"]
            end

            def pipeline_id
              env["CF_BUILD_ID"]
            end

            def pipeline_name
              env["CF_PIPELINE_NAME"]
            end

            def pipeline_url
              env["CF_BUILD_URL"]
            end

            def git_branch_or_tag
              env["CF_BRANCH"]
            end

            def ci_env_vars
              {
                "CF_BUILD_ID" => env["CF_BUILD_ID"]
              }.to_json
            end
          end
        end
      end
    end
  end
end
