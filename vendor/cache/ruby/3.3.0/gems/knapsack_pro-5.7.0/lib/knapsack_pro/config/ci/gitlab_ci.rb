# frozen_string_literal: true

# https://docs.gitlab.com/ce/ci/variables/
module KnapsackPro
  module Config
    module CI
      class GitlabCI < Base
        def node_total
          ENV['CI_NODE_TOTAL']
        end

        def node_index
          return unless ENV['GITLAB_CI']
          # GitLab 11.5
          index = ENV['CI_NODE_INDEX']
          index.to_i - 1 if index
        end

        def node_build_id
          ENV['CI_PIPELINE_ID'] || # Gitlab Release 9.0+
          ENV['CI_BUILD_ID'] # Gitlab Release 8.x
        end

        def commit_hash
          ENV['CI_COMMIT_SHA'] || # Gitlab Release 9.0+
          ENV['CI_BUILD_REF'] # Gitlab Release 8.x
        end

        def branch
          ENV['CI_COMMIT_REF_NAME'] || # Gitlab Release 9.0+
          ENV['CI_BUILD_REF_NAME'] # Gitlab Release 8.x
        end

        def project_dir
          ENV['CI_PROJECT_DIR']
        end

        def user_seat
          ENV['GITLAB_USER_NAME'] || # Gitlab Release 10.0
          ENV['GITLAB_USER_EMAIL'] # Gitlab Release 8.12
        end

        def detected
          ENV.key?('GITLAB_CI') ? self.class : nil
        end

        def fixed_queue_split
          true
        end

        def ci_provider
          "Gitlab CI"
        end
      end
    end
  end
end
