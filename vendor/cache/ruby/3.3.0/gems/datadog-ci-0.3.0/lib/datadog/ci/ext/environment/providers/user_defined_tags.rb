# frozen_string_literal: true

require_relative "base"
require_relative "../../git"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # Parses user defined git data from the environment variables
          # User documentation: https://docs.datadoghq.com/continuous_integration/troubleshooting/#data-appears-in-test-runs-but-not-tests
          class UserDefinedTags < Base
            def git_repository_url
              env[Git::ENV_REPOSITORY_URL]
            end

            def git_commit_sha
              env[Git::ENV_COMMIT_SHA]
            end

            def git_branch
              env[Git::ENV_BRANCH]
            end

            def git_tag
              env[Git::ENV_TAG]
            end

            def git_commit_message
              env[Git::ENV_COMMIT_MESSAGE]
            end

            def git_commit_author_name
              env[Git::ENV_COMMIT_AUTHOR_NAME]
            end

            def git_commit_author_email
              env[Git::ENV_COMMIT_AUTHOR_EMAIL]
            end

            def git_commit_author_date
              env[Git::ENV_COMMIT_AUTHOR_DATE]
            end

            def git_commit_committer_name
              env[Git::ENV_COMMIT_COMMITTER_NAME]
            end

            def git_commit_committer_email
              env[Git::ENV_COMMIT_COMMITTER_EMAIL]
            end

            def git_commit_committer_date
              env[Git::ENV_COMMIT_COMMITTER_DATE]
            end
          end
        end
      end
    end
  end
end
