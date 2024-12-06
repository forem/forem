# frozen_string_literal: true

# https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables
module KnapsackPro
  module Config
    module CI
      class GithubActions < Base
        def node_total
          # not provided
        end

        def node_index
          # not provided
        end

        def node_build_id
          # A unique number for each run within a repository. This number does not change if you re-run the workflow run.
          ENV['GITHUB_RUN_ID']
        end

        def node_retry_count
          # A unique number for each attempt of a particular workflow run in a repository.
          # This number begins at 1 for the workflow run's first attempt, and increments with each re-run.
          run_attempt = ENV['GITHUB_RUN_ATTEMPT']
          return unless run_attempt
          run_attempt.to_i - 1
        end

        def commit_hash
          ENV['GITHUB_SHA']
        end

        def branch
          # GITHUB_REF - The branch or tag ref that triggered the workflow. For example, refs/heads/feature-branch-1.
          # If neither a branch or tag is available for the event type, the variable will not exist.
          ENV['GITHUB_REF'] || ENV['GITHUB_SHA']
        end

        def project_dir
          ENV['GITHUB_WORKSPACE']
        end

        def user_seat
          ENV['GITHUB_ACTOR']
        end

        def detected
          ENV.key?('GITHUB_ACTIONS') ? self.class : nil
        end

        def fixed_queue_split
          true
        end

        def ci_provider
          "GitHub Actions"
        end
      end
    end
  end
end
