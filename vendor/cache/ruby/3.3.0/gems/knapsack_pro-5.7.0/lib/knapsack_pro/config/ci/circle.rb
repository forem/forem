# frozen_string_literal: true

module KnapsackPro
  module Config
    module CI
      class Circle < Base
        def node_total
          ENV['CIRCLE_NODE_TOTAL']
        end

        def node_index
          ENV['CIRCLE_NODE_INDEX']
        end

        def node_build_id
          ENV['CIRCLE_BUILD_NUM']
        end

        def commit_hash
          ENV['CIRCLE_SHA1']
        end

        def branch
          ENV['CIRCLE_BRANCH']
        end

        def project_dir
          ENV['CIRCLE_WORKING_DIRECTORY']
        end

        def user_seat
          ENV['CIRCLE_USERNAME'] || ENV['CIRCLE_PR_USERNAME']
        end

        def detected
          ENV.key?('CIRCLECI') ? self.class : nil
        end

        def fixed_queue_split
          false
        end

        def ci_provider
          "CircleCI"
        end
      end
    end
  end
end
