# frozen_string_literal: true

module Datadog
  module Core
    module Git
      # Defines constants for Git tags
      module Ext
        GIT_SHA_LENGTH = 40

        TAG_BRANCH = 'git.branch'
        TAG_REPOSITORY_URL = 'git.repository_url'
        TAG_TAG = 'git.tag'

        TAG_COMMIT_AUTHOR_DATE = 'git.commit.author.date'
        TAG_COMMIT_AUTHOR_EMAIL = 'git.commit.author.email'
        TAG_COMMIT_AUTHOR_NAME = 'git.commit.author.name'
        TAG_COMMIT_COMMITTER_DATE = 'git.commit.committer.date'
        TAG_COMMIT_COMMITTER_EMAIL = 'git.commit.committer.email'
        TAG_COMMIT_COMMITTER_NAME = 'git.commit.committer.name'
        TAG_COMMIT_MESSAGE = 'git.commit.message'
        TAG_COMMIT_SHA = 'git.commit.sha'

        ENV_REPOSITORY_URL = 'DD_GIT_REPOSITORY_URL'
        ENV_COMMIT_SHA = 'DD_GIT_COMMIT_SHA'
        ENV_BRANCH = 'DD_GIT_BRANCH'
        ENV_TAG = 'DD_GIT_TAG'
        ENV_COMMIT_MESSAGE = 'DD_GIT_COMMIT_MESSAGE'
        ENV_COMMIT_AUTHOR_NAME = 'DD_GIT_COMMIT_AUTHOR_NAME'
        ENV_COMMIT_AUTHOR_EMAIL = 'DD_GIT_COMMIT_AUTHOR_EMAIL'
        ENV_COMMIT_AUTHOR_DATE = 'DD_GIT_COMMIT_AUTHOR_DATE'
        ENV_COMMIT_COMMITTER_NAME = 'DD_GIT_COMMIT_COMMITTER_NAME'
        ENV_COMMIT_COMMITTER_EMAIL = 'DD_GIT_COMMIT_COMMITTER_EMAIL'
        ENV_COMMIT_COMMITTER_DATE = 'DD_GIT_COMMIT_COMMITTER_DATE'
      end
    end
  end
end
