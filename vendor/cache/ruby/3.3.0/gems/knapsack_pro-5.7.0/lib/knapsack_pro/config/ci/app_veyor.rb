# frozen_string_literal: true

# https://www.appveyor.com/docs/environment-variables/
module KnapsackPro
  module Config
    module CI
      class AppVeyor < Base
        def node_total
          # not provided
        end

        def node_index
          # not provided
        end

        def node_build_id
          ENV['APPVEYOR_BUILD_ID']
        end

        def commit_hash
          ENV['APPVEYOR_REPO_COMMIT']
        end

        def branch
          ENV['APPVEYOR_REPO_BRANCH']
        end

        def project_dir
          ENV['APPVEYOR_BUILD_FOLDER']
        end

        def user_seat
          ENV['APPVEYOR_REPO_COMMIT_AUTHOR']
        end

        def detected
          ENV.key?('APPVEYOR') ? self.class : nil
        end

        def fixed_queue_split
          false
        end

        def ci_provider
          "AppVeyor"
        end
      end
    end
  end
end
