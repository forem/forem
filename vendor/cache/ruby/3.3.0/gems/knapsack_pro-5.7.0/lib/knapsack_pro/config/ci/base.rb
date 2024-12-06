# frozen_string_literal: true

module KnapsackPro
  module Config
    module CI
      class Base
        def node_total
        end

        def node_index
        end

        def node_build_id
        end

        def node_retry_count
        end

        def commit_hash
        end

        def branch
        end

        def project_dir
        end

        def user_seat
        end

        def detected
        end

        def fixed_queue_split
          true
        end

        def ci_provider
          return 'AWS CodeBuild' if ENV.key?('CODEBUILD_BUILD_ARN')
          return 'Azure Pipelines' if ENV.key?('SYSTEM_TEAMFOUNDATIONCOLLECTIONURI')
          return 'Bamboo' if ENV.key?('bamboo_planKey')
          return 'Bitbucket Pipelines' if ENV.key?('BITBUCKET_COMMIT')
          return 'Buddy.works' if ENV.key?('BUDDY')
          return 'Drone.io' if ENV.key?('DRONE')
          return 'Google Cloud Build' if ENV.key?('BUILDER_OUTPUT')
          return 'Jenkins' if ENV.key?('JENKINS_URL')
          return 'TeamCity' if ENV.key?('TEAMCITY_VERSION')
          return 'Other' if KnapsackPro::Config::Env.ci?

          nil
        end
      end
    end
  end
end
