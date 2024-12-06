# frozen_string_literal: true

require "json"

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Circle CI: https://circleci.com/
          # Environment variables docs: https://circleci.com/docs/variables/#built-in-environment-variables
          class Circleci < Base
            def self.handles?(env)
              env.key?("CIRCLECI")
            end

            def provider_name
              "circleci"
            end

            def job_url
              env["CIRCLE_BUILD_URL"]
            end

            def job_name
              env["CIRCLE_JOB"]
            end

            def pipeline_id
              env["CIRCLE_WORKFLOW_ID"]
            end

            def pipeline_name
              env["CIRCLE_PROJECT_REPONAME"]
            end

            def pipeline_url
              "https://app.circleci.com/pipelines/workflows/#{env["CIRCLE_WORKFLOW_ID"]}"
            end

            def workspace_path
              env["CIRCLE_WORKING_DIRECTORY"]
            end

            def git_repository_url
              env["CIRCLE_REPOSITORY_URL"]
            end

            def git_commit_sha
              env["CIRCLE_SHA1"]
            end

            def git_branch
              env["CIRCLE_BRANCH"]
            end

            def git_tag
              env["CIRCLE_TAG"]
            end

            def git_commit_author_name
              env["BUILD_REQUESTEDFORID"]
            end

            def git_commit_author_email
              env["BUILD_REQUESTEDFOREMAIL"]
            end

            def git_commit_message
              env["BUILD_SOURCEVERSIONMESSAGE"]
            end

            def ci_env_vars
              {
                "CIRCLE_WORKFLOW_ID" => env["CIRCLE_WORKFLOW_ID"],
                "CIRCLE_BUILD_NUM" => env["CIRCLE_BUILD_NUM"]
              }.to_json
            end
          end
        end
      end
    end
  end
end
