# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Actions Workflows API
    #
    # @see https://developer.github.com/v3/actions/workflows
    module ActionsWorkflows
      # Get the workflows in a repository
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      #
      # @return [Sawyer::Resource] the total count and an array of workflows
      # @see https://developer.github.com/v3/actions/workflows/#list-repository-workflows
      def workflows(repo, options = {})
        paginate "#{Repository.path repo}/actions/workflows", options
      end
      alias list_workflows workflows

      # Get single workflow in a repository
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer, String] Id or file name of the workflow
      #
      # @return [Sawyer::Resource] A single workflow
      # @see https://developer.github.com/v3/actions/workflows/#get-a-workflow
      def workflow(repo, id, options = {})
        get "#{Repository.path repo}/actions/workflows/#{id}", options
      end

      # Create a workflow dispatch event
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer, String] Id or file name of the workflow
      # @param ref [String] A SHA, branch name, or tag name
      #
      # @return [Boolean] True if event was dispatched, false otherwise
      # @see https://docs.github.com/en/rest/reference/actions#create-a-workflow-dispatch-event
      def workflow_dispatch(repo, id, ref, options = {})
        boolean_from_response :post, "#{Repository.path repo}/actions/workflows/#{id}/dispatches", options.merge({ ref: ref })
      end

      # Enable a workflow
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer, String] Id or file name of the workflow
      #
      # @return [Boolean] True if workflow was enabled, false otherwise
      # @see https://docs.github.com/en/rest/actions/workflows#enable-a-workflow
      def workflow_enable(repo, id, options = {})
        boolean_from_response :put, "#{Repository.path repo}/actions/workflows/#{id}/enable", options
      end

      # Disable a workflow
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer, String] Id or file name of the workflow
      #
      # @return [Boolean] True if workflow was disabled, false otherwise
      # @see https://docs.github.com/en/rest/actions/workflows#disable-a-workflow
      def workflow_disable(repo, id, options = {})
        boolean_from_response :put, "#{Repository.path repo}/actions/workflows/#{id}/disable", options
      end
    end
  end
end
