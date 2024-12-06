# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the OauthApplications API
    #
    # @see https://developer.github.com/v3/apps/oauth_applications
    module OauthApplications
      # Check if a token is valid.
      #
      # Applications can check if a token is valid without rate limits.
      #
      # @param access_token [String] 40 character GitHub OAuth access token
      #
      # @return [Sawyer::Resource] A single authorization for the authenticated user
      # @see https://developer.github.com/v3/apps/oauth_applications/#check-a-token
      #
      # @example
      #  client = Octokit::Client.new(:client_id => 'abcdefg12345', :client_secret => 'secret')
      #  client.check_token('deadbeef1234567890deadbeef987654321')
      def check_token(access_token, options = {})
        options[:access_token] = access_token

        key    = options.delete(:client_id)     || client_id
        secret = options.delete(:client_secret) || client_secret

        as_app(key, secret) do |app_client|
          app_client.post "applications/#{client_id}/token", options
        end
      end
      alias check_application_authorization check_token

      # Reset a token
      #
      # Applications can reset a token without requiring a user to re-authorize.
      #
      # @param access_token [String] 40 character GitHub OAuth access token
      #
      # @return [Sawyer::Resource] A single authorization for the authenticated user
      # @see https://developer.github.com/v3/apps/oauth_applications/#reset-a-token
      #
      # @example
      #  client = Octokit::Client.new(:client_id => 'abcdefg12345', :client_secret => 'secret')
      #  client.reset_token('deadbeef1234567890deadbeef987654321')
      def reset_token(access_token, options = {})
        options[:access_token] = access_token

        key    = options.delete(:client_id)     || client_id
        secret = options.delete(:client_secret) || client_secret

        as_app(key, secret) do |app_client|
          app_client.patch "applications/#{client_id}/token", options
        end
      end
      alias reset_application_authorization reset_token

      # Delete an app token
      #
      # Applications can revoke (delete) a token
      #
      # @param access_token [String] 40 character GitHub OAuth access token
      #
      # @return [Boolean] Result
      # @see https://developer.github.com/v3/apps/oauth_applications/#delete-an-app-token
      #
      # @example
      #  client = Octokit::Client.new(:client_id => 'abcdefg12345', :client_secret => 'secret')
      #  client.delete_token('deadbeef1234567890deadbeef987654321')
      def delete_app_token(access_token, options = {})
        options[:access_token] = access_token

        key    = options.delete(:client_id)     || client_id
        secret = options.delete(:client_secret) || client_secret

        begin
          as_app(key, secret) do |app_client|
            app_client.delete "applications/#{client_id}/token", options
            app_client.last_response.status == 204
          end
        rescue Octokit::NotFound
          false
        end
      end
      alias delete_application_authorization delete_app_token
      alias revoke_application_authorization delete_app_token

      # Delete an app authorization
      #
      # OAuth application owners can revoke a grant for their OAuth application and a specific user.
      #
      # @param access_token [String] 40 character GitHub OAuth access token
      #
      # @return [Boolean] Result
      # @see https://developer.github.com/v3/apps/oauth_applications/#delete-an-app-token
      #
      # @example
      #  client = Octokit::Client.new(:client_id => 'abcdefg12345', :client_secret => 'secret')
      #  client.delete_app_authorization('deadbeef1234567890deadbeef987654321')
      def delete_app_authorization(access_token, options = {})
        options[:access_token] = access_token

        key    = options.delete(:client_id)     || client_id
        secret = options.delete(:client_secret) || client_secret

        begin
          as_app(key, secret) do |app_client|
            app_client.delete "applications/#{client_id}/grant", options
            app_client.last_response.status == 204
          end
        rescue Octokit::NotFound
          false
        end
      end
    end
  end
end
