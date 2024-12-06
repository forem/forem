# frozen_string_literal: true

module KnapsackPro
  module Config
    module CI
      # Semaphore Classic is deprecated
      # https://semaphoreci.com/blog/semaphore-classic-deprecation
      class Semaphore < Base
        def node_total
          ENV['SEMAPHORE_THREAD_COUNT']
        end

        def node_index
          index = ENV['SEMAPHORE_CURRENT_THREAD']
          index.to_i - 1 if index
        end

        def node_build_id
          ENV['SEMAPHORE_BUILD_NUMBER']
        end

        def commit_hash
          ENV['REVISION']
        end

        def branch
          ENV['BRANCH_NAME']
        end

        def project_dir
          ENV['SEMAPHORE_PROJECT_DIR']
        end

        def detected
          ENV.key?('SEMAPHORE_BUILD_NUMBER') ? self.class : nil
        end

        def fixed_queue_split
          false
        end

        def ci_provider
          "Semaphore CI 1.0"
        end
      end
    end
  end
end
