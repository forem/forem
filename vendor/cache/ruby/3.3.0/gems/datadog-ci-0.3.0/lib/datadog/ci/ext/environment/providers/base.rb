# frozen_string_literal: true

module Datadog
  module CI
    module Ext
      module Environment
        module Providers
          class Base
            attr_reader :env

            def self.handles?(_env)
              false
            end

            def initialize(env)
              @env = env
            end

            def job_name
            end

            def job_url
            end

            def pipeline_id
            end

            def pipeline_name
            end

            def pipeline_number
            end

            def pipeline_url
            end

            def provider_name
            end

            def stage_name
            end

            def workspace_path
            end

            def node_labels
            end

            def node_name
            end

            def ci_env_vars
            end

            def git_branch
              return @branch if defined?(@branch)

              set_branch_and_tag
              @branch
            end

            def git_repository_url
            end

            def git_tag
              return @tag if defined?(@tag)

              set_branch_and_tag
              @tag
            end

            def git_branch_or_tag
            end

            def git_commit_author_date
            end

            def git_commit_author_email
            end

            def git_commit_author_name
            end

            def git_commit_committer_date
            end

            def git_commit_committer_email
            end

            def git_commit_committer_name
            end

            def git_commit_message
            end

            def git_commit_sha
            end

            private

            def set_branch_and_tag
              branch_or_tag_string = git_branch_or_tag
              @branch = @tag = nil

              # @type var branch_or_tag_string: untyped
              if branch_or_tag_string && branch_or_tag_string.include?("tags/")
                @tag = branch_or_tag_string
              else
                @branch = branch_or_tag_string
              end

              [@branch, @tag]
            end
          end
        end
      end
    end
  end
end
