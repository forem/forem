# frozen_string_literal: true

require "json"

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Azure Pipelines: https://azure.microsoft.com/en-us/products/devops/pipelines
          # Environment variables docs: https://learn.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml
          class Azure < Base
            def self.handles?(env)
              env.key?("TF_BUILD")
            end

            def provider_name
              "azurepipelines"
            end

            def pipeline_url
              return unless url_defined?

              @pipeline_url ||= "#{team_foundation_server_uri}#{team_project_id}/_build/results?buildId=#{build_id}"
            end

            def job_url
              return unless url_defined?

              @job_url ||= "#{pipeline_url}&view=logs&j=#{env["SYSTEM_JOBID"]}&t=#{env["SYSTEM_TASKINSTANCEID"]}"
            end

            def workspace_path
              env["BUILD_SOURCESDIRECTORY"]
            end

            def pipeline_id
              build_id
            end

            def pipeline_number
              build_id
            end

            def pipeline_name
              env["BUILD_DEFINITIONNAME"]
            end

            def stage_name
              env["SYSTEM_STAGEDISPLAYNAME"]
            end

            def job_name
              env["SYSTEM_JOBDISPLAYNAME"]
            end

            def git_repository_url
              env["SYSTEM_PULLREQUEST_SOURCEREPOSITORYURI"] || env["BUILD_REPOSITORY_URI"]
            end

            def git_commit_sha
              env["SYSTEM_PULLREQUEST_SOURCECOMMITID"] || env["BUILD_SOURCEVERSION"]
            end

            def git_branch_or_tag
              env["SYSTEM_PULLREQUEST_SOURCEBRANCH"] || env["BUILD_SOURCEBRANCH"] || env["BUILD_SOURCEBRANCHNAME"]
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
                "SYSTEM_TEAMPROJECTID" => env["SYSTEM_TEAMPROJECTID"],
                "BUILD_BUILDID" => env["BUILD_BUILDID"],
                "SYSTEM_JOBID" => env["SYSTEM_JOBID"]
              }.to_json
            end

            private

            def build_id
              env["BUILD_BUILDID"]
            end

            def team_foundation_server_uri
              env["SYSTEM_TEAMFOUNDATIONSERVERURI"]
            end

            def team_project_id
              env["SYSTEM_TEAMPROJECTID"]
            end

            def url_defined?
              !(build_id && team_foundation_server_uri && team_project_id).nil?
            end
          end
        end
      end
    end
  end
end
