# frozen_string_literal: true

module KnapsackPro
  module Config
    module CI
      class Buildkite < Base
        def node_total
          ENV['BUILDKITE_PARALLEL_JOB_COUNT']
        end

        def node_index
          ENV['BUILDKITE_PARALLEL_JOB']
        end

        def node_build_id
          ENV['BUILDKITE_BUILD_NUMBER']
        end

        def node_retry_count
          ENV['BUILDKITE_RETRY_COUNT']
        end

        def commit_hash
          ENV['BUILDKITE_COMMIT']
        end

        def branch
          ENV['BUILDKITE_BRANCH']
        end

        def project_dir
          ENV['BUILDKITE_BUILD_CHECKOUT_PATH']
        end

        def user_seat
          ENV['BUILDKITE_BUILD_AUTHOR'] || ENV['BUILDKITE_BUILD_CREATOR']
        end

        def detected
          ENV.key?('BUILDKITE') ? self.class : nil
        end

        def fixed_queue_split
          true
        end

        def ci_provider
          "Buildkite"
        end
      end
    end
  end
end
