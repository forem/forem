# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Buddy: https://buddy.works/
          # Environment variables docs: https://buddy.works/docs/pipelines/environment-variables
          class Buddy < Base
            def self.handles?(env)
              env.key?("BUDDY")
            end

            def provider_name
              "buddy"
            end

            def pipeline_id
              "#{env["BUDDY_PIPELINE_ID"]}/#{env["BUDDY_EXECUTION_ID"]}"
            end

            def pipeline_name
              env["BUDDY_PIPELINE_NAME"]
            end

            def pipeline_number
              env["BUDDY_EXECUTION_ID"]
            end

            def pipeline_url
              env["BUDDY_EXECUTION_URL"]
            end

            def workspace_path
              env["CI_WORKSPACE_PATH"]
            end

            def git_repository_url
              env["BUDDY_SCM_URL"]
            end

            def git_commit_sha
              env["BUDDY_EXECUTION_REVISION"]
            end

            def git_branch
              env["BUDDY_EXECUTION_BRANCH"]
            end

            def git_tag
              env["BUDDY_EXECUTION_TAG"]
            end

            def git_commit_message
              env["BUDDY_EXECUTION_REVISION_MESSAGE"]
            end

            def git_commit_committer_name
              env["BUDDY_EXECUTION_REVISION_COMMITTER_NAME"]
            end

            def git_commit_committer_email
              env["BUDDY_EXECUTION_REVISION_COMMITTER_EMAIL"]
            end
          end
        end
      end
    end
  end
end
