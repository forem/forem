# frozen_string_literal: true

module KnapsackPro
  module Config
    module CI
      class CirrusCI < Base
        def node_total
          ENV['CI_NODE_TOTAL']
        end

        def node_index
          ENV['CI_NODE_INDEX']
        end

        def node_build_id
          ENV['CIRRUS_BUILD_ID']
        end

        def commit_hash
          ENV['CIRRUS_CHANGE_IN_REPO']
        end

        def branch
          ENV['CIRRUS_BRANCH']
        end

        def project_dir
          ENV['CIRRUS_WORKING_DIR']
        end

        def user_seat
          # not provided
        end

        def detected
          ENV.key?('CIRRUS_CI') ? self.class : nil
        end

        def fixed_queue_split
          false
        end

        def ci_provider
          "Cirrus CI"
        end
      end
    end
  end
end
