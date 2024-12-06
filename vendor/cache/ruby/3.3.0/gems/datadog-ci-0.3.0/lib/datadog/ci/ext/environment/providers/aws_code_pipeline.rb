# frozen_string_literal: true

require_relative "base"

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          # AWS CodePipeline: https://aws.amazon.com/codepipeline/
          # Environment variables docs: https://docs.aws.amazon.com/codepipeline/latest/userguide/actions-variables.html
          # AWS CodeBuild: https://aws.amazon.com/codebuild/
          # Environment variable docs: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
          class AwsCodePipeline < Base
            def self.handles?(env)
              !env["CODEBUILD_INITIATOR"].nil? && env["CODEBUILD_INITIATOR"].start_with?("codepipeline")
            end

            def provider_name
              "awscodepipeline"
            end

            def pipeline_id
              env["DD_PIPELINE_EXECUTION_ID"]
            end

            def ci_env_vars
              {
                "CODEBUILD_BUILD_ARN" => env["CODEBUILD_BUILD_ARN"],
                "DD_PIPELINE_EXECUTION_ID" => env["DD_PIPELINE_EXECUTION_ID"],
                "DD_ACTION_EXECUTION_ID" => env["DD_ACTION_EXECUTION_ID"]
              }.to_json
            end
          end
        end
      end
    end
  end
end
