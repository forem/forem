# frozen_string_literal: true

require_relative "git"
require_relative "environment/extractor"

module Datadog
  module CI
    module Ext
      # Defines constants for CI tags
      module Environment
        TAG_JOB_NAME = "ci.job.name"
        TAG_JOB_URL = "ci.job.url"
        TAG_PIPELINE_ID = "ci.pipeline.id"
        TAG_PIPELINE_NAME = "ci.pipeline.name"
        TAG_PIPELINE_NUMBER = "ci.pipeline.number"
        TAG_PIPELINE_URL = "ci.pipeline.url"
        TAG_PROVIDER_NAME = "ci.provider.name"
        TAG_STAGE_NAME = "ci.stage.name"
        TAG_WORKSPACE_PATH = "ci.workspace_path"
        TAG_NODE_LABELS = "ci.node.labels"
        TAG_NODE_NAME = "ci.node.name"
        TAG_CI_ENV_VARS = "_dd.ci.env_vars"

        HEX_NUMBER_REGEXP = /[0-9a-f]{40}/i.freeze

        module_function

        def tags(env)
          # Extract metadata from CI provider environment variables
          tags = Environment::Extractor.new(env).tags

          # If user defined metadata is defined, overwrite
          tags.merge!(
            Environment::Extractor.new(env, provider_klass: Providers::UserDefinedTags).tags
          )

          # Fill out tags from local git as fallback
          local_git_tags = Environment::Extractor.new(env, provider_klass: Providers::LocalGit).tags
          local_git_tags.each do |key, value|
            tags[key] ||= value
          end

          ensure_post_conditions(tags)

          tags
        end

        def ensure_post_conditions(tags)
          validate_repository_url(tags[Git::TAG_REPOSITORY_URL])
          validate_git_sha(tags[Git::TAG_COMMIT_SHA])
        end

        def validate_repository_url(repo_url)
          return if !repo_url.nil? && !repo_url.empty?

          Datadog.logger.error("DD_GIT_REPOSITORY_URL is not set or empty; no repo URL was automatically extracted")
        end

        def validate_git_sha(git_sha)
          message = "DD_GIT_COMMIT_SHA must be a full-length git SHA."

          if git_sha.nil? || git_sha.empty?
            message += " No value was set and no SHA was automatically extracted."
            Datadog.logger.error(message)
            return
          end

          if git_sha.length < Git::SHA_LENGTH
            message += " Expected SHA length #{Git::SHA_LENGTH}, was #{git_sha.length}."
            Datadog.logger.error(message)
            return
          end

          unless HEX_NUMBER_REGEXP =~ git_sha
            message += " Expected SHA to be a valid HEX number, got #{git_sha}."
            Datadog.logger.error(message)
          end
        end
      end
    end
  end
end
