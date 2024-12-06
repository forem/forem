# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Appveyor: https://www.appveyor.com/
          # Environment variables docs: https://www.appveyor.com/docs/environment-variables/
          class Appveyor < Base
            def self.handles?(env)
              env.key?("APPVEYOR")
            end

            def provider_name
              "appveyor"
            end

            def pipeline_url
              url
            end

            def job_url
              url
            end

            def workspace_path
              env["APPVEYOR_BUILD_FOLDER"]
            end

            def pipeline_id
              env["APPVEYOR_BUILD_ID"]
            end

            def pipeline_name
              env["APPVEYOR_REPO_NAME"]
            end

            def pipeline_number
              env["APPVEYOR_BUILD_NUMBER"]
            end

            def git_repository_url
              return nil unless github_repo_provider?

              "https://github.com/#{env["APPVEYOR_REPO_NAME"]}.git"
            end

            def git_commit_sha
              return nil unless github_repo_provider?

              env["APPVEYOR_REPO_COMMIT"]
            end

            def git_branch
              return nil unless github_repo_provider?

              env["APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH"] || env["APPVEYOR_REPO_BRANCH"]
            end

            def git_tag
              return nil unless github_repo_provider?

              env["APPVEYOR_REPO_TAG_NAME"]
            end

            def git_commit_author_name
              env["APPVEYOR_REPO_COMMIT_AUTHOR"]
            end

            def git_commit_author_email
              env["APPVEYOR_REPO_COMMIT_AUTHOR_EMAIL"]
            end

            def git_commit_message
              commit_message = env["APPVEYOR_REPO_COMMIT_MESSAGE"]
              if commit_message
                extended = env["APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED"]
                commit_message = "#{commit_message}\n#{extended}" if extended
              end
              commit_message
            end

            private

            def github_repo_provider?
              return @github_repo_provider if defined?(@github_repo_provider)

              @github_repo_provider = env["APPVEYOR_REPO_PROVIDER"] == "github"
            end

            def url
              @url ||= "https://ci.appveyor.com/project/#{env["APPVEYOR_REPO_NAME"]}/builds/#{env["APPVEYOR_BUILD_ID"]}"
            end
          end
        end
      end
    end
  end
end
