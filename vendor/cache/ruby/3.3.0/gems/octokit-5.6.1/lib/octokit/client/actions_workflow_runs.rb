# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Actions Workflows runs API
    #
    # @see https://docs.github.com/rest/actions/workflow-runs
    module ActionsWorkflowRuns
      # List all runs for a repository workflow
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param workflow [Integer, String] Id or file name of the workflow
      # @option options [String] :actor Optional filtering by a user
      # @option options [String] :branch Optional filtering by a branch
      # @option options [String] :event Optional filtering by the event type
      # @option options [String] :status Optional filtering by a status or conclusion
      #
      # @return [Sawyer::Resource] the total count and an array of workflows
      # @see https://developer.github.com/v3/actions/workflow-runs/#list-workflow-runs
      def workflow_runs(repo, workflow, options = {})
        paginate "#{Repository.path repo}/actions/workflows/#{workflow}/runs", options
      end
      alias list_workflow_runs workflow_runs

      # List all workflow runs for a repository
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @option options [String] :actor Optional filtering by the login of a user
      # @option options [String] :branch Optional filtering by a branch
      # @option options [String] :event Optional filtering by the event type (e.g. push, pull_request, issue)
      # @option options [String] :status Optional filtering by a status or conclusion (e.g. success, completed...)
      #
      # @return [Sawyer::Resource] the total count and an array of workflows
      # @see https://developer.github.com/v3/actions/workflow-runs/#list-repository-workflow-runs
      def repository_workflow_runs(repo, options = {})
        paginate "#{Repository.path repo}/actions/runs", options
      end
      alias list_repository_workflow_runs repository_workflow_runs

      # Get a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of a workflow run
      #
      # @return [Sawyer::Resource] Run information
      # @see https://developer.github.com/v3/actions/workflow-runs/#get-a-workflow-run
      def workflow_run(repo, id, options = {})
        get "#{Repository.path repo}/actions/runs/#{id}", options
      end

      # Re-runs a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of a workflow run
      #
      # @return [Boolean] Returns true if the re-run request was accepted
      # @see https://developer.github.com/v3/actions/workflow-runs/#re-run-a-workflow
      def rerun_workflow_run(repo, id, options = {})
        boolean_from_response :post, "#{Repository.path repo}/actions/runs/#{id}/rerun", options
      end

      # Cancels a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of a workflow run
      #
      # @return [Boolean] Returns true if the cancellation was accepted
      # @see https://developer.github.com/v3/actions/workflow-runs/#cancel-a-workflow-run
      def cancel_workflow_run(repo, id, options = {})
        boolean_from_response :post, "#{Repository.path repo}/actions/runs/#{id}/cancel", options
      end

      # Deletes a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of a workflow run
      #
      # @return [Boolean] Returns true if the run is deleted
      # @see https://docs.github.com/en/rest/reference/actions#delete-a-workflow-run
      def delete_workflow_run(repo, id, options = {})
        boolean_from_response :delete, "#{Repository.path repo}/actions/runs/#{id}", options
      end

      # Get a download url for archived log files of a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of a workflow run
      #
      # @return [String] URL to the archived log files of the run
      # @see https://developer.github.com/v3/actions/workflow-runs/#download-workflow-run-logs
      def workflow_run_logs(repo, id, options = {})
        url = "#{Repository.path repo}/actions/runs/#{id}/logs"

        response = client_without_redirects.head(url, options)
        response.headers['Location']
      end

      # Delete all log files of a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of a workflow run
      #
      # @return [Boolean] Returns true if the logs are deleted
      # @see https://developer.github.com/v3/actions/workflow-runs/#delete-workflow-run-logs
      def delete_workflow_run_logs(repo, id, options = {})
        boolean_from_response :delete, "#{Repository.path repo}/actions/runs/#{id}/logs", options
      end

      # Get workflow run usage
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of a workflow run
      #
      # @return [Sawyer::Resource] Run usage
      # @see https://developer.github.com/v3/actions/workflow-runs/#get-workflow-run-usage
      def workflow_run_usage(repo, id, options = {})
        get "#{Repository.path repo}/actions/runs/#{id}/timing", options
      end
    end
  end
end
