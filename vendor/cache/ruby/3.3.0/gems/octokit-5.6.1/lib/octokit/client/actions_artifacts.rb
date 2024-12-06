# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Actions Artifacts API
    #
    # @see https://developer.github.com/v3/actions/artifacts
    module ActionsArtifacts
      # List all artifacts for a repository
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      #
      # @return [Sawyer::Resource] the total count and an array of artifacts
      # @see https://developer.github.com/v3/actions/artifacts#list-artifacts-for-a-repository
      def repository_artifacts(repo, options = {})
        paginate "#{Repository.path repo}/actions/artifacts", options
      end

      # List all artifacts for a workflow run
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param workflow_run_id [Integer] Id of a workflow run
      #
      # @return [Sawyer::Resource] the total count and an array of artifacts
      # @see https://docs.github.com/en/rest/actions/artifacts#list-workflow-run-artifacts
      def workflow_run_artifacts(repo, workflow_run_id, options = {})
        paginate "#{Repository.path repo}/actions/runs/#{workflow_run_id}/artifacts", options
      end

      # Get an artifact
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of an artifact
      #
      # @return [Sawyer::Resource] Artifact information
      # @see https://docs.github.com/en/rest/actions/artifacts#get-an-artifact
      def artifact(repo, id, options = {})
        get "#{Repository.path repo}/actions/artifacts/#{id}", options
      end

      # Get a download URL for an artifact
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of an artifact
      #
      # @return [String] URL to the .zip archive of the artifact
      # @see https://docs.github.com/en/rest/actions/artifacts#download-an-artifact
      def artifact_download_url(repo, id, options = {})
        url = "#{Repository.path repo}/actions/artifacts/#{id}/zip"

        response = client_without_redirects.head(url, options)
        response.headers['Location']
      end

      # Delete an artifact
      #
      # @param repo [Integer, String, Repository, Hash] A GitHub repository
      # @param id [Integer] Id of an artifact
      #
      # @return [Boolean] Return true if the artifact was successfully deleted
      # @see https://docs.github.com/en/rest/actions/artifacts#delete-an-artifact
      def delete_artifact(repo, id, options = {})
        boolean_from_response :delete, "#{Repository.path repo}/actions/artifacts/#{id}", options
      end
    end
  end
end
