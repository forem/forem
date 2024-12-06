# frozen_string_literal: true

require_relative "providers/base"
require_relative "providers/appveyor"
require_relative "providers/aws_code_pipeline"
require_relative "providers/azure"
require_relative "providers/bitbucket"
require_relative "providers/bitrise"
require_relative "providers/buddy"
require_relative "providers/buildkite"
require_relative "providers/circleci"
require_relative "providers/codefresh"
require_relative "providers/github_actions"
require_relative "providers/gitlab"
require_relative "providers/jenkins"
require_relative "providers/teamcity"
require_relative "providers/travis"

require_relative "providers/local_git"
require_relative "providers/user_defined_tags"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          PROVIDERS = [
            Providers::Appveyor,
            Providers::AwsCodePipeline,
            Providers::Azure,
            Providers::Bitbucket,
            Providers::Bitrise,
            Providers::Buddy,
            Providers::Buildkite,
            Providers::Circleci,
            Providers::Codefresh,
            Providers::GithubActions,
            Providers::Gitlab,
            Providers::Jenkins,
            Providers::Teamcity,
            Providers::Travis
          ]

          def self.for_environment(env)
            provider_klass = PROVIDERS.find { |klass| klass.handles?(env) }
            provider_klass = Providers::Base if provider_klass.nil?

            provider_klass.new(env)
          end
        end
      end
    end
  end
end
