# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Branches for HEAD API
    #
    # @see https://developer.github.com/v3/repos/commits/
    module CommitBranches
      # List branches for a single HEAD commit
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param sha [String] The SHA of the commit whose branches will be fetched
      # @return [Array]  List of branches
      # @see https://developer.github.com/v3/repos/commits/#list-branches-for-head-commit
      def commit_branches(repo, sha, options = {})
        paginate "#{Repository.path repo}/commits/#{sha}/branches-where-head", options
      end
    end
  end
end
