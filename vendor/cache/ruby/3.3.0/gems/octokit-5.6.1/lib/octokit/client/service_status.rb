# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the GitHub Status API
    #
    # @see https://status.github.com/api
    module ServiceStatus
      # Root for status API
      # @private
      SUMMARY_ROOT    = 'https://www.githubstatus.com/api/v2/summary.json'
      STATUS_ROOT     = 'https://www.githubstatus.com/api/v2/status.json'
      COMPONENTS_ROOT = 'https://www.githubstatus.com/api/v2/components.json'

      # Returns a summary with the current status and the last status messages.
      #
      # @return [<Sawyer::Resource>] GitHub status summary
      # @see https://www.githubstatus.com/api#summory
      def github_status_summary
        get(SUMMARY_ROOT)
      end

      # Returns the current system status
      #
      # @return [Sawyer::Resource] GitHub status
      # @see https://www.githubstatus.com/api#status
      def github_status
        get(STATUS_ROOT)
      end

      # Returns the last human communication, status, and timestamp.
      #
      # @return [Sawyer::Resource] GitHub status last message
      # @see https://www.githubstatus.com/api/#components
      def github_status_last_message
        get(COMPONENTS_ROOT).components.first
      end

      # Returns the most recent human communications with status and timestamp.
      #
      # @return [Array<Sawyer::Resource>] GitHub status messages
      # @see https://www.githubstatus.com/api#components
      def github_status_messages
        get(COMPONENTS_ROOT).components
      end
    end
  end
end
