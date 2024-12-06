# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Commit Pulls API
    #
    # @see https://developer.github.com/v3/repos/comments/
    module CommitPulls
      # List pulls for a single commit
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param sha [String] The SHA of the commit whose pulls will be fetched
      # @return [Array]  List of commit pulls
      # @see https://developer.github.com/v3/repos/commits/#list-pull-requests-associated-with-commit
      def commit_pulls(repo, sha, options = {})
        paginate "#{Repository.path repo}/commits/#{sha}/pulls", options
      end
    end
  end
end
