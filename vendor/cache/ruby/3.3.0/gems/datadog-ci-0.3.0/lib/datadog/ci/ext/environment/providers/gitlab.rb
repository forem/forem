# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Gitlab CI: https://docs.gitlab.com/ee/ci/
          # Environment variables docs: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
          class Gitlab < Base
            def self.handles?(env)
              env.key?("GITLAB_CI")
            end

            def provider_name
              "gitlab"
            end

            def job_name
              env["CI_JOB_NAME"]
            end

            def job_url
              env["CI_JOB_URL"]
            end

            def pipeline_id
              env["CI_PIPELINE_ID"]
            end

            def pipeline_name
              env["CI_PROJECT_PATH"]
            end

            def pipeline_number
              env["CI_PIPELINE_IID"]
            end

            def pipeline_url
              env["CI_PIPELINE_URL"]
            end

            def stage_name
              env["CI_JOB_STAGE"]
            end

            def workspace_path
              env["CI_PROJECT_DIR"]
            end

            def node_name
              env["CI_RUNNER_ID"]
            end

            def node_labels
              env["CI_RUNNER_TAGS"]
            end

            def git_repository_url
              env["CI_REPOSITORY_URL"]
            end

            def git_commit_sha
              env["CI_COMMIT_SHA"]
            end

            def git_branch
              env["CI_COMMIT_REF_NAME"]
            end

            def git_tag
              env["CI_COMMIT_TAG"]
            end

            def git_commit_author_name
              name, _ = extract_name_email
              name
            end

            def git_commit_author_email
              _, email = extract_name_email
              email
            end

            def git_commit_author_date
              env["CI_COMMIT_TIMESTAMP"]
            end

            def git_commit_message
              env["CI_COMMIT_MESSAGE"]
            end

            def ci_env_vars
              {
                "CI_PROJECT_URL" => env["CI_PROJECT_URL"],
                "CI_PIPELINE_ID" => env["CI_PIPELINE_ID"],
                "CI_JOB_ID" => env["CI_JOB_ID"]
              }.to_json
            end

            private

            def extract_name_email
              return @name_email_tuple if defined?(@name_email_tuple)

              name_and_email_string = env["CI_COMMIT_AUTHOR"]
              if name_and_email_string.include?("<") && (match = /^([^<]*)<([^>]*)>$/.match(name_and_email_string))
                name = match[1]
                name = name.strip if name
                email = match[2]
                return @name_email_tuple = [name, email] if name && email
              end

              @name_email_tuple = [nil, name_and_email_string]
            end
          end
        end
      end
    end
  end
end
