# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Bitbucket Pipelines: https://bitbucket.org/product/features/pipelines
          # Environment variables docs: https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/
          class Bitbucket < Base
            def self.handles?(env)
              env.key?("BITBUCKET_COMMIT")
            end

            # overridden methods
            def provider_name
              "bitbucket"
            end

            def pipeline_id
              env["BITBUCKET_PIPELINE_UUID"] ? env["BITBUCKET_PIPELINE_UUID"].tr("{}", "") : nil
            end

            def pipeline_name
              env["BITBUCKET_REPO_FULL_NAME"]
            end

            def pipeline_number
              env["BITBUCKET_BUILD_NUMBER"]
            end

            def pipeline_url
              url
            end

            def job_url
              url
            end

            def workspace_path
              env["BITBUCKET_CLONE_DIR"]
            end

            def git_repository_url
              env["BITBUCKET_GIT_SSH_ORIGIN"] || env["BITBUCKET_GIT_HTTP_ORIGIN"]
            end

            def git_commit_sha
              env["BITBUCKET_COMMIT"]
            end

            def git_branch
              env["BITBUCKET_BRANCH"]
            end

            def git_tag
              env["BITBUCKET_TAG"]
            end

            private

            def url
              "https://bitbucket.org/#{env["BITBUCKET_REPO_FULL_NAME"]}/addon/pipelines/home#" \
                "!/results/#{env["BITBUCKET_BUILD_NUMBER"]}"
            end
          end
        end
      end
    end
  end
end
