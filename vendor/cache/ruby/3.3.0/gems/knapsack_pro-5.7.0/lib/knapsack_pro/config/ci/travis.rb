# frozen_string_literal: true

module KnapsackPro
  module Config
    module CI
      class Travis < Base
        def node_build_id
          ENV['TRAVIS_BUILD_NUMBER']
        end

        def commit_hash
          ENV['TRAVIS_COMMIT']
        end

        def branch
          ENV['TRAVIS_BRANCH']
        end

        def project_dir
          ENV['TRAVIS_BUILD_DIR']
        end

        def user_seat
          # not provided
        end

        def detected
          ENV.key?('TRAVIS') ? self.class : nil
        end

        def fixed_queue_split
          true
        end

        def ci_provider
          "Travis CI"
        end
      end
    end
  end
end
