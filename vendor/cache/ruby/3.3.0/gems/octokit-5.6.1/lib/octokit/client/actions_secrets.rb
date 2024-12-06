# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Actions Secrets API
    #
    # @see https://developer.github.com/v3/actions/secrets/
    module ActionsSecrets
      # Get public key for secrets encryption
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @return [Hash] key_id and key
      # @see https://developer.github.com/v3/actions/secrets/#get-your-public-key
      def get_public_key(repo)
        get "#{Repository.path repo}/actions/secrets/public-key"
      end

      # List secrets
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @return [Hash] total_count and list of secrets (each item is hash with name, created_at and updated_at)
      # @see https://developer.github.com/v3/actions/secrets/#list-secrets-for-a-repository
      def list_secrets(repo)
        paginate "#{Repository.path repo}/actions/secrets"
      end

      # Get a secret
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param name [String] Name of secret
      # @return [Hash] name, created_at and updated_at
      # @see https://developer.github.com/v3/actions/secrets/#get-a-secret
      def get_secret(repo, name)
        get "#{Repository.path repo}/actions/secrets/#{name}"
      end

      # Create or update secrets
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param name [String] Name of secret
      # @param options [Hash] encrypted_value and key_id
      # @see https://developer.github.com/v3/actions/secrets/#create-or-update-a-secret-for-a-repository
      def create_or_update_secret(repo, name, options)
        put "#{Repository.path repo}/actions/secrets/#{name}", options
      end

      # Delete a secret
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param name [String] Name of secret
      # @see https://developer.github.com/v3/actions/secrets/#delete-a-secret-from-a-repository
      def delete_secret(repo, name)
        boolean_from_response :delete, "#{Repository.path repo}/actions/secrets/#{name}"
      end
    end
  end
end
