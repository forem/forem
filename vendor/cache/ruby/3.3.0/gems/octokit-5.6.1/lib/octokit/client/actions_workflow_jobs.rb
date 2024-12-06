# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Actions Workflows jobs API
    #
    # @see https://docs.github.com/rest/actions/workflow-jobs
    module ActionsWorkflowJobs
      # Get a job for a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param job_id [Integer, String] Id of the job
      #
      # @return [Sawyer::Resource] Job information
      # @see https://docs.github.com/rest/actions/workflow-jobs#get-a-job-for-a-workflow-run
      def workflow_run_job(repo, job_id, options = {})
        get "#{Repository.path repo}/actions/jobs/#{job_id}", options
      end

      # Download job logs for a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param job_id [Integer, String] Id of the job
      #
      # @return [String] URL to the archived log files of the job
      # @see https://docs.github.com/rest/actions/workflow-jobs#download-job-logs-for-a-workflow-run
      def workflow_run_job_logs(repo, job_id, options = {})
        url = "#{Repository.path repo}/actions/jobs/#{job_id}/logs"

        response = client_without_redirects.head(url, options)
        response.headers['Location']
      end

      # List jobs for a workflow run attempt
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param run_id [Integer, String] Id of the workflow run
      # @param attempt_number [Integer, String] Attempt number of the workflow run
      #
      # @return [Sawyer::Resource] Jobs information
      # @see https://docs.github.com/rest/actions/workflow-jobs#list-jobs-for-a-workflow-run-attempt
      def workflow_run_attempt_jobs(repo, run_id, attempt_number, options = {})
        paginate "#{Repository.path repo}/actions/runs/#{run_id}/attempts/#{attempt_number}/jobs", options
      end
      alias list_workflow_run_attempt_jobs workflow_run_attempt_jobs

      # List jobs for a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param run_id [Integer, String] Id of the workflow run
      # @option options [String] :filter Optional filtering by a `completed_at` timestamp
      #
      # @return [Sawyer::Resource] Jobs information
      # @see https://docs.github.com/rest/actions/workflow-jobs#list-jobs-for-a-workflow-run
      def workflow_run_jobs(repo, run_id, options = {})
        paginate "#{Repository.path repo}/actions/runs/#{run_id}/jobs", options
      end
      alias list_workflow_run_jobs workflow_run_jobs
    end
  end
end
