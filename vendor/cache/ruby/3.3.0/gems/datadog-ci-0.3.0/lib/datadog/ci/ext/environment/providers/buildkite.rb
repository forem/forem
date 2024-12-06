# frozen_string_literal: true

require "json"

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Buildkite: https://buildkite.com/
          # Environment variables docs: https://buildkite.com/docs/pipelines/environment-variables
          class Buildkite < Base
            def self.handles?(env)
              env.key?("BUILDKITE")
            end

            def provider_name
              "buildkite"
            end

            def job_url
              "#{env["BUILDKITE_BUILD_URL"]}##{env["BUILDKITE_JOB_ID"]}"
            end

            def pipeline_id
              env["BUILDKITE_BUILD_ID"]
            end

            def pipeline_name
              env["BUILDKITE_PIPELINE_SLUG"]
            end

            def pipeline_number
              env["BUILDKITE_BUILD_NUMBER"]
            end

            def pipeline_url
              env["BUILDKITE_BUILD_URL"]
            end

            def node_name
              env["BUILDKITE_AGENT_ID"]
            end

            def node_labels
              labels = env
                .select { |key| key.start_with?("BUILDKITE_AGENT_META_DATA_") }
                .map { |key, value| "#{key.to_s.sub("BUILDKITE_AGENT_META_DATA_", "").downcase}:#{value}" }
                .sort_by(&:length)

              labels.to_json unless labels.empty?
            end

            def workspace_path
              env["BUILDKITE_BUILD_CHECKOUT_PATH"]
            end

            def git_repository_url
              env["BUILDKITE_REPO"]
            end

            def git_commit_sha
              env["BUILDKITE_COMMIT"]
            end

            def git_branch
              env["BUILDKITE_BRANCH"]
            end

            def git_tag
              env["BUILDKITE_TAG"]
            end

            def git_commit_author_name
              env["BUILDKITE_BUILD_AUTHOR"]
            end

            def git_commit_author_email
              env["BUILDKITE_BUILD_AUTHOR_EMAIL"]
            end

            def git_commit_message
              env["BUILDKITE_MESSAGE"]
            end

            def ci_env_vars
              {
                "BUILDKITE_BUILD_ID" => env["BUILDKITE_BUILD_ID"],
                "BUILDKITE_JOB_ID" => env["BUILDKITE_JOB_ID"]
              }.to_json
            end
          end
        end
      end
    end
  end
end
