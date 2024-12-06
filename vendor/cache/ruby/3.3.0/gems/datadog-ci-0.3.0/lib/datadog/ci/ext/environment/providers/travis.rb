# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Travis CI: https://www.travis-ci.com/
          # Environment variables docs: https://docs.travis-ci.com/user/environment-variables#default-environment-variables
          class Travis < Base
            def self.handles?(env)
              env.key?("TRAVIS")
            end

            def provider_name
              "travisci"
            end

            def job_url
              env["TRAVIS_JOB_WEB_URL"]
            end

            def pipeline_id
              env["TRAVIS_BUILD_ID"]
            end

            def pipeline_name
              env["TRAVIS_REPO_SLUG"]
            end

            def pipeline_number
              env["TRAVIS_BUILD_NUMBER"]
            end

            def pipeline_url
              env["TRAVIS_BUILD_WEB_URL"]
            end

            def workspace_path
              env["TRAVIS_BUILD_DIR"]
            end

            def git_repository_url
              "https://github.com/#{env["TRAVIS_REPO_SLUG"]}.git"
            end

            def git_commit_sha
              env["TRAVIS_COMMIT"]
            end

            def git_branch
              env["TRAVIS_PULL_REQUEST_BRANCH"] || env["TRAVIS_BRANCH"]
            end

            def git_tag
              env["TRAVIS_TAG"]
            end

            def git_commit_message
              env["TRAVIS_COMMIT_MESSAGE"]
            end
          end
        end
      end
    end
  end
end
