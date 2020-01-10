module Oauth
  class TokensController < Doorkeeper::TokensController
    # OAuth 2.0 Token Revocation - http://tools.ietf.org/html/rfc7009
    def revoke
      # The authorization server, if applicable, first authenticates the client
      # and checks its ownership of the provided token.
      #
      # Doorkeeper does not use the token_type_hint logic described in the
      # RFC 7009 due to the refresh token implementation that is a field in
      # the access token model.
      if authorized?
        revoke_token
        Webhook::DestroyWorker.perform_async(token.resource_owner_id, token.application_id)
        render json: {}, status: :ok
      else
        error_description = I18n.t(:unauthorized, scope: %i[doorkeeper errors messages revoke])
        revocation_error_response = { error: :unauthorized_client, error_description: error_description }

        render json: revocation_error_response, status: :forbidden
      end
    end
  end
end
